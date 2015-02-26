Capistrano::Configuration.instance(:must_exist).load do
  rails_root =
    case
      when defined?(RAILS_ROOT)
        RAILS_ROOT
      when defined?(Rails.root)
        Rails.root
      else
        nil
    end

  if rails_root.nil?
    Capistrano::Configuration.instance.load_paths.each do |load_path| 
      if test(?e, File.join(load_path, 'Capfile'))
        rails_root = File.expand_path(load_path)
        break
      end
    end
  end

  abort 'could not determine rails_root!' unless rails_root
        
  namespace :sekrets do
    task :upload_key do
    
      src = File.join(rails_root, '.sekrets.key')
      dst = File.join(latest_release, '.sekrets.key')
      
      if test(?s, src)
        upload(src, dst, :recursive => true)
      end
    end
  end
  after('deploy:finalize_update', 'sekrets:upload_key')
end
