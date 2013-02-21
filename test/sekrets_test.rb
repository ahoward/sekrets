# -*- encoding : utf-8 -*-

Testing Sekrets do

#
  testing 'basic Sekrets.encrypt/Sekrets.decrypt functionality' do
    plaintext = '42'
    encrypted = assert{ Sekrets.encrypt(:key, plaintext) }
    decrypted = assert{ Sekrets.decrypt(:key, encrypted) }
    assert{ decrypted == plaintext }
    assert{ Sekrets.cycle(:key, plaintext) == plaintext }
  end

#
  testing 'Sekrets.key_for precedence' do
    environment = {
      'SEKRETS_KEY' => 'env key'
    }

    paths = {
      'plaintext' => 'plaintext',
      '.plaintext.key' => 'file key'
    }

    options = {
      :key => 'options key'
    }

    with_environment(environment) do
      assert{ Sekrets.key_for(options) == 'options key' }
    end

    with_environment(environment) do
      with_paths(paths) do
        assert{ Sekrets.key_for(options) == 'options key' }
      end
    end

    with_environment(environment) do
      with_paths(paths) do
        assert{ Sekrets.key_for(:path => 'plaintext') == 'file key' }
        assert{ Sekrets.key_for('plaintext') == 'file key' }
      end
    end

    with_environment(environment) do
      assert{ Sekrets.key_for(:path => 'plaintext') == 'env key' }
    end

    with_paths 'plaintext' => 'plaintext' do
      command = %[ #{ ruby } -r #{ $libdir }/sekrets.rb -e'puts Sekrets.key_for("plaintext")' ]

      key = nil
      PTY.spawn(command) do |r, w, pid|
        w.puts('foobar')
        w.close
        key = r.read.to_s.strip
      end
      assert{ key =~ /foobar/ }

      key = `#{ command } </dev/null`
      assert{ key !~ /foobar/ }
    end
  end

#
  testing 'Sekrets.write/Secrets.read' do
    tmpdir do
      path = 'plaintext'
      content = 'content'
      key = '42'

      encrypted = assert{ Sekrets.write(path, content, key) }

      assert{ encrypted != content }
      assert{ IO.read(path) != encrypted } 
      assert{ Sekrets.decrypt(key, encrypted) == content }
      assert{ Sekrets.decrypt(key, IO.read(path)) == content }


      assert{ Sekrets.read(path, key) == content }
    end
  end

  testing 'Sekrets.settings_for' do
    tmpdir do
      path = 'config.yml'
      config = {:key => :val, :a => :b, :x => :y}
      content = config.to_yaml
      key = '42'

      encrypted = assert{ Sekrets.write(path, content, key) }
      assert{ Sekrets.settings_for(path, key) == config }
    end
  end

protected

  def with_paths(specification = {}, &block)
    paths = []

    tmpdir do |tmp|
      specification.each do |path, contents|
        path = File.join(Dir.pwd, path.to_s)
        FileUtils.mkdir_p(File.dirname(path))

        open(path, 'wb'){|fd| fd.write(contents)}
      end

      block.call()
    end
  end

  def with_path(*args, &block)
    with_paths(*args, &block)
  end

  def with_environment(options = {}, &block)
    options.each do |key, val|
      ENV[key.to_s] = val.to_s
    end
    block.call
  ensure
    options.each do |key, val|
      ENV.delete(key.to_s)
    end
  end

  def tmpdir(*args, &block)
    Sekrets.tmpdir(*args, &block)
  end

  def ruby
    @ruby ||= (
      c = RbConfig::CONFIG
      bindir = c["bindir"] || c['BINDIR']
      ruby_install_name = c['ruby_install_name'] || c['RUBY_INSTALL_NAME'] || 'ruby'
      ruby_ext = c['EXEEXT'] || ''
      File.join(bindir, (ruby_install_name + ruby_ext))
    )
  end
end


BEGIN {
  $testdir = File.dirname(File.expand_path(__FILE__))
  $testlibdir = File.join($testdir, 'lib')
  $rootdir = File.dirname($testdir)
  $libdir = File.join($rootdir, 'lib')
  $LOAD_PATH.push($libdir)
  $LOAD_PATH.push($testlibdir)

  Dir.chdir($testdir)

  require 'tmpdir'
  require 'fileutils'
  require 'pty'

  begin
    require 'pry'
  rescue Object
    nil
  end

  require 'testing'
  require 'sekrets'
}
