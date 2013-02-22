class Sekrets
#
  Fattr(:env){ 'SEKRETS_KEY' }
  Fattr(:editor){ ENV['SEKRETS_EDITOR'] || ENV['EDITOR'] || 'vim' }
  Fattr(:root){ defined?(Rails.root) ? Rails.root : '.' }
  Fattr(:project_key){ File.join(root, '.sekrets.key') }
  Fattr(:global_key){ File.join(File.expand_path('~'), '.sekrets.key') }

#
  def Sekrets.key_for(*args)
    options = Map.options_for!(args)
    path = args.shift || options[:path]

    if options.has_key?(:key)
      key = options[:key]
      return(key)
    end

    path = path_for(path)

    if path
      dirname, basename = File.split(path)

      keyfiles =
        Coerce.list_of_strings(
          [:keyfile, :keyfiles].map{|k| options[k]},
          %W[ #{ dirname }/.#{ basename }.key #{ dirname }/.#{ basename }.k ]
        )

      keyfiles.each do |file|
        if test(?s, file)
          key = IO.binread(file).strip
          return(key)
        end
      end
    end

    if Sekrets.project_key and test(?s, Sekrets.project_key)
      return IO.binread(Sekrets.project_key).strip
    end

    env_key = (options[:env] || Sekrets.env).to_s
    if ENV.has_key?(env_key)
      key = ENV[env_key]
      return(key)
    end

    if Sekrets.global_key and test(?s, Sekrets.global_key)
      return IO.binread(Sekrets.global_key).strip
    end

    unless options[:prompt] == false
      if console?
        key = Sekrets.ask(path)
        return(key)
      end
    end

    return nil
  end

#
  def Sekrets.key_for!(*args, &block)
    key = Sekrets.key_for(*args, &block)
    raise(ArgumentError, 'no key!') unless key
    key
  end

#
  def Sekrets.read(*args, &block)
    options = Map.options_for!(args)
    path = args.shift || options[:path]
    key = args.shift || Sekrets.key_for!(path, options)

    return nil unless test(?s, path)

    encrypted = IO.binread(path)
    decrypted = Sekrets.decrypt(key, encrypted)
    new(decrypted)
  end

#
  def Sekrets.write(*args, &block)
    options = Map.options_for!(args)
    path = args.shift || options[:path]
    content = args.shift || options[:content]
    key = args.shift || Sekrets.key_for!(path, options)

    dirname, basename = File.split(File.expand_path(path))
    FileUtils.mkdir_p(dirname)

    encrypted = Sekrets.encrypt(key, content)

    tmp = path + '.tmp'
    IO.binwrite(tmp, encrypted)
    FileUtils.mv(tmp, path)

    encrypted
    new(encrypted)
  end

#
  def Sekrets.settings_for(*args, &block)
    decrypted = read(*args, &block)

    if decrypted
      expanded = ERB.new(decrypted).result(TOPLEVEL_BINDING)
      object = YAML.load(expanded)
      object.is_a?(Hash) ? Map.for(object) : object
    end
  end

#
  def Sekrets.prompt_for(*words)
    ["sekrets:", words, "> "].flatten.compact.join(' ')
  end

#
  def Sekrets.ask(question)
    @highline ||= HighLine.new
    @highline.ask(prompt_for(question))
  end

#
  def Sekrets.console?
    STDIN.tty?
  end

#
  def Sekrets.tmpdir(&block)
    dirname = File.join(Dir.tmpdir, 'sekrets', Process.ppid.to_s, Process.pid.to_s, rand.to_s)

    FileUtils.mkdir_p(dirname)

    cleanup = proc do
      if dirname and test(?d, dirname)
        FileUtils.rm_rf(dirname)
      end
    end

    if block
      begin
        Dir.chdir(dirname) do
          block.call(dirname)
        end
      ensure
        cleanup.call
      end
    else
      at_exit{ cleanup.call }
      dirname
    end
  end
 
#
  def Sekrets.openw(arg, &block)
    opened = false
    atomic_move = proc{}

    io =
      case
        when arg.respond_to?(:read)
          arg
        when arg.to_s.strip == '-'
          STDOUT
        else
          opened = true
          path = File.expand_path(arg.to_s)
          dirname, basename = File.split(path)
          FileUtils.mkdir_p(dirname)
          tmp = path + ".sekrets.tmp.#{ Process.ppid }.#{ Process.pid }"
          at_exit{ FileUtils.rm_f(tmp) }
          atomic_move = proc{ FileUtils.mv(tmp, path) }
          open(tmp, 'wb+')
      end

    close = 
      proc do
        io.close if opened
        atomic_move.call
      end

    if block
      begin
        block.call(io)
      ensure
        close.call
      end
    else
      at_exit{ close.call }
      io
    end
  end

#
  def Sekrets.openr(arg, &block)
    opened = false

    io =
      case
        when arg.respond_to?(:read)
          arg
        when arg.to_s.strip == '-'
          STDIN
        else
          opened = true
          open(arg, 'rb+')
      end

    close = 
      proc do
        io.close if opened
      end

    if block
      begin
        block.call(io)
      ensure
        close.call
      end
    else
      at_exit{ close.call }
      io
    end
  end

#
  def Sekrets.path_for(object)
    path = nil

    if object.is_a?(String) or object.is_a?(Pathname)
      return(path = object.to_s)
    end

    [:original_path, :original_filename, :path, :filename, :pathname].each do |msg|
      if object.respond_to?(msg)
        path = object.send(msg)
        break
      end
    end

    path
  end

  def Sekrets.binstub
    @binstub ||= (
      unindent(
        <<-__
          #! /usr/bin/env ruby

          require 'pathname'
          ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../../Gemfile",
            Pathname.new(__FILE__).realpath)
            
          require 'rubygems'
          require 'bundler/setup'

          ciphertext = File.expand_path('ciphertext', File.dirname(__FILE__))
          ENV['SEKRETS_ARGV'] = "edit \#{ ciphertext }"

          load Gem.bin_path('sekrets', 'sekrets')
        __
      )
    )
  end

  def Sekrets.unindent(string)
    indent = string.split("\n").select {|line| !line.strip.empty? }.map {|line| line.index(/[^\s]/) }.compact.min || 0
    string.gsub(/^[[:blank:]]{#{indent}}/, '')
  end

  def Sekrets.unindent!(string)
    string.replace(string.unindent)
  end

#
  module Blowfish
    def cipher(mode, key, data)
      cipher = OpenSSL::Cipher::Cipher.new('bf-cbc').send(mode)
      cipher.key = Digest::SHA256.digest(key.to_s)
      cipher.update(data) << cipher.final
    end

    def encrypt(key, data)
      cipher(:encrypt, key, data)
    end

    def decrypt(key, text)
      cipher(:decrypt, key, text)
    end

    def cycle(key, data)
      decrypt(key, encrypt(key, data))
    end

    def recrypt(old_key, new_key, data)
      encrypt(new_key, decrypt(old_key, data))
    end

    extend(self)
  end

  extend(Blowfish)
end


Sekret = Sekrets



BEGIN {

  require 'openssl'
  require 'fileutils'
  require 'erb'
  require 'yaml'
  require 'tmpdir'

  class Sekrets < ::String
    Version = '1.3.0' unless defined?(Version)

    class << Sekrets
      def version
        Sekrets::Version
      end

      def dependencies
        {
          'highline' => [ 'highline' , ' >= 1.6.15'  ] , 
          'map'      => [ 'map'      , ' >= 6.3.0'   ]  , 
          'fattr'    => [ 'fattr'    , ' >= 2.2.1'   ]  , 
          'coerce'   => [ 'coerce'   , ' >= 0.0.3'   ]  , 
          'main'     => [ 'main'     , ' >= 5.1.1'   ]  , 
        }
      end

      def libdir(*args, &block)
        @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
        args.empty? ? @libdir : File.join(@libdir, *args)
      ensure
        if block
          begin
            $LOAD_PATH.unshift(@libdir)
            block.call()
          ensure
            $LOAD_PATH.shift()
          end
        end
      end

      def load(*libs)
        libs = libs.join(' ').scan(/[^\s+]+/)
        Sekrets.libdir{ libs.each{|lib| Kernel.load(lib) } }
      end
    end
  end

  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  Sekrets.dependencies.each do |lib, dependency|
    gem(*dependency) if defined?(gem)
    require(lib)
  end

  Sekrets.fattr(:description){
    <<-__

      foobar

    __
  }

  if defined?(Rails::Engine)

    class Sekrets
      class Engine < Rails::Engine
        engine_name :sekrets

        rake_tasks do
          namespace :sekrets do
            namespace :generate do
              task :editor do
                editor = File.join(Rails.root, 'sekrets', 'editor')

                unless test(?s, editor)
                  FileUtils.mkdir_p(File.dirname(editor))
                  open(editor, 'wb'){|fd| fd.write(Sekrets.binstub)}
                end
              end
            end
          end
        end
      end
    end

  end
}
