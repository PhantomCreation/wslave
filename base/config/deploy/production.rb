require 'yaml'
require 'date'
require 'wslave_sage'

opts = YAML.load_file('config/definitions.yml', aliases: true)
db_info = YAML.load_file('config/database.yml', aliases: true)

deploy_user = opts['deployer']['user']
deploy_group = opts['deployer']['www_data_group']
host_addr = opts['deployer']['host']['production']
multisite_root = opts['deployer']['root']
site_fqdn = opts['deployer']['fqdn']['production']

disable_rsync = (opts.include?('options') && opts['options'].include?('rsync_enabled') && 
          opts['options']['rsync_enabled'] == false)

if (opts['deployer'].include?('branch') && opts['deployer']['branch'].include?('production'))
  set :branch, opts['deployer']['branch']['production']
end

role :web, "#{deploy_user}@#{host_addr}" 

set :tmp_dir, "#{multisite_root}/tmp"
deploy_path = "#{multisite_root}/#{site_fqdn}"

set :linked_dirs, %w{public/wp-content/uploads public/wordpress public/wp-content/upgrade public/wp-content/plugins public/data tmp}
set :linked_files, %w{public/wp-config.php}

set :deploy_to, deploy_path

namespace :deploy do
  desc "Generate wp-config.php for profile"
  task :wp_config do
    on roles(:web) do
      invoke 'deploy:check:make_linked_dirs'
      require_relative '../deploy-tools/gen-wp-config'
      FileUtils.mkdir('./tmp') unless Dir.exist?('./tmp')
      GenerateWPConfig('production', './tmp')
      upload! './tmp/wp-config.php', "#{deploy_path}/shared/public/wp-config.php"
    end
  end

  desc 'Syncs the wordpress directory with rsync'
  task :sync_wp do
    on roles(:web) do
      `rsync -avzPhu --delete ./public/wordpress/ #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wordpress/`
    end
  end

  desc 'Uploads the uploads directory'
  task :upload_wp do
    on roles(:web) do
      upload! './public/wordpress', "#{deploy_path}/shared/public/", recursive: true
    end
  end

  desc 'Syncs the uploads directory with rsync'
  task :sync_uploads do
    on roles(:web) do
      `rsync -avzPhu --delete ./public/wp-content/uploads/ #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/uploads/`
    end
  end

  desc 'Uploads the uploads directory'
  task :upload_uploads do
    on roles(:web) do
      upload! './public/wp-content/uploads', "#{deploy_path}/shared/public/wp-content/", recursive: true
    end
  end

  desc 'Syncs the plugins directory with rsync'
  task :sync_plugins do
    on roles(:web) do
      `rsync -avzPhu --delete ./public/wp-content/plugins/ #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/plugins/`
    end
  end

  desc 'Uploads the plugins directory'
  task :upload_plugins do
    on roles(:web) do
      upload! './public/wp-content/plugins', "#{deploy_path}/shared/public/wp-content/", recursive: true
    end
  end

  desc 'Syncs the static data directory with rsync'
  task :sync_static_data do
    on roles(:web) do
      `rsync -avzPhu --delete ./public/data/ #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/data/`
    end
  end

  desc 'Uploads the static data directory'
  task :upload_static_data do
    on roles(:web) do
      upload! './public/data', "#{deploy_path}/shared/public/data/", recursive: true
    end
  end

  desc 'Builds and Syncs the project Sage theme'
  task :sync_sage_theme do
    on roles(:web) do
      wss = WSlaveSage.new()
      sage_theme_name = wss.theme_name?
      if (sage_theme_name == '')
        puts "Couldn't find a Sage theme for this project."
      else
        wss.production()
        `rsync -avzPhu --delete ./public/wp-content/themes/#{sage_theme_name}/vendor/ #{deploy_user}@#{host_addr}:#{deploy_path}/current/public/wp-content/themes/#{sage_theme_name}/vendor/`
        `rsync -avzPhu --delete ./public/wp-content/themes/#{sage_theme_name}/dist/ #{deploy_user}@#{host_addr}:#{deploy_path}/current/public/wp-content/themes/#{sage_theme_name}/dist/`
      end
    end
  end

  desc 'Builds and Uploads the project Sage theme'
  task :upload_sage_theme do
    on roles(:web) do
      wss = WSlaveSage.new()
      sage_theme_name = wss.theme_name?
      if (sage_theme_name == '')
        puts "Couldn't find a Sage theme for this project."
      else
        wss.production()
        upload! "./public/wp-content/themes/#{sage_theme_name}/vendor/", "#{deploy_path}/current/public/wp-content/themes/#{sage_theme_name}/", recursive: true
        upload! "./public/wp-content/themes/#{sage_theme_name}/dist/", "#{deploy_path}/current/public/wp-content/themes/#{sage_theme_name}/", recursive: true
      end
    end
  end

  desc 'Builds and Deploys the project Sage theme'
  task :sage do
    on roles(:web) do
      if disable_rsync
        invoke('deploy:upload_sage_theme')
      else
        invoke('deploy:sync_sage_theme')
      end
    end
  end

  desc 'Finds and replaces localhost:8000 / localhost:8001and your Staging address with the Production address'
  task :chikan do
    on roles(:web) do
      puts 'Replacing localhost:8000 / localhost:8001 and Staging URLs with Production URLs...'

      # Set an anchor to first homogonize instances of URL's, then replace all the anchors
      anchor = "URL_REPLACEMENT_ANCHOR_00000"

      # Create a backup, download it, and remove remote copy
      execute "mkdir -p #{deploy_path}/db/tmp"
      execute "mysqldump --opt --user=#{db_info['production']['username']} --password=#{db_info['production']['password']} --host=#{db_info['production']['host']} #{db_info['production']['database']} > #{deploy_path}/db/tmp/wordpress.sql"
      FileUtils.mkdir_p('./db/tmp') unless Dir.exist?('./db/tmp')
      download! "#{deploy_path}/db/tmp/wordpress.sql", "db/tmp/wordpress.sql"
      execute "rm #{deploy_path}/db/tmp/*.sql"

      # Regex replace in file
      db_data = File.read('db/tmp/wordpress.sql')

      # This may seem roundabout, but in order to avoid mangling the target URL we need to first
      # replace instances of it with something that won't match
      db_data = db_data.gsub(/#{opts['deployer']['fqdn']['production']}/, anchor)

      # Set production URL's to the anchor
      if opts['deployer']['fqdn']['production'] != ''
        db_data = db_data.gsub(/#{opts['deployer']['fqdn']['production']}/, anchor)
      end

      # Set localhost entries to the anchor
      db_data = db_data.gsub(/localhost\%3A8000/, anchor)
      db_data = db_data.gsub(/localhost:8000/, anchor)
      db_data = db_data.gsub(/localhost\%3A8001/, anchor)
      db_data = db_data.gsub(/localhost:8001/, anchor)

      # Replace anchors with the correct target URL
      db_data = db_data.gsub(anchor, "#{opts['deployer']['fqdn']['production']}")

      # Save results
      File.open('db/tmp/wordpress.sql', "w") {|file| file.puts db_data }

      # Upload file and seed
      upload! 'db/tmp/wordpress.sql', "#{deploy_path}/db/tmp/wordpress.sql"
      execute "mysql -h#{db_info['production']['host']} -u#{db_info['production']['username']} -p#{db_info['production']['password']} #{db_info['production']['database']} < #{deploy_path}/db/tmp/wordpress.sql"
      execute "rm #{deploy_path}/db/tmp/*.sql"

      # Remove work file
      # `rm db/tmp/wordpress.sql`
    end
  end

  desc 'Sets ownership permissions'
  task :set_permissions do
    on roles(:web) do
      puts 'Setting permissions'
      if deploy_group != nil
        puts "Recrusively setting group to #{deploy_group}..."
        execute "chown -R :#{deploy_group} #{deploy_path}"
        puts 'Allowing group level Write permission...'
        execute "chmod -R g+w #{deploy_path}"
      end
    end
  end

  desc 'Creates an additional symlink at the path specified in definitions.yml to current/public'
  task :set_symlink do
    on roles(:web) do
      puts 'Setting symlink'
      if (opts['deployer'].include?('symlink') && opts['deployer']['symlink'].include?('production'))
        execute "ln -s #{deploy_path}/current/public #{opts['deployer']['root']}/#{opts['deployer']['symlink']['production']}"
      end
    end
  end

  desc 'Perform special seed tasks required on intial seed'
  task :initial do
    on roles(:web) do
      invoke!('deploy:check:directories')
      invoke!('deploy:check:linked_dirs')
      invoke!('deploy:check:make_linked_dirs')
      invoke('deploy:wp_config')
      if disable_rsync
        invoke('deploy:upload_wp')
        invoke('deploy:upload_plugins')
        invoke('deploy:upload_uploads')
        invoke('deploy:upload_static_data')
      else
        invoke('deploy:sync_wp')
        invoke('deploy:sync_plugins')
        invoke('deploy:sync_uploads')
        invoke('deploy:sync_static_data')
      end
      invoke('deploy')
      invoke('db:seed')
      invoke('deploy:chikan')
      invoke('deploy:sage')
      invoke('deploy:set_permissions')
      invoke('deploy:set_symlink')
    end
  end

  desc 'Clear out remote DB tables and delete all remote files in deploy target directory'
  task :destruct do
    on roles(:web) do
      execute "mysql --user=#{db_info['production']['username']} " \
        "--password=#{db_info['production']['password']} --host=#{db_info['production']['host']} " \
        "-Nse 'show tables' #{db_info['production']['database']} | " \
        "while read table; do echo \"drop table $table;\"; done | " \
        "mysql --user=#{db_info['production']['username']} " \
        "--password=#{db_info['production']['password']} --host=#{db_info['production']['host']} " \
        "#{db_info['production']['database']}"

      execute "rm -rf #{deploy_path}/*"
    end
  end
end

namespace :db do
  desc "Backup DB"
  task :backup do
    on roles(:web) do
      timestamp = DateTime.now
      execute "mkdir -p #{deploy_path}/db/backups/production/"
      execute "mysqldump --opt --user=#{db_info['production']['username']} --password=#{db_info['production']['password']} --host=#{db_info['production']['host']} #{db_info['production']['database']} > #{deploy_path}/db/backups/production/#{timestamp}.sql"
      FileUtils.mkdir_p('./db/production') unless Dir.exist?('./db/production')
      download! "#{deploy_path}/db/backups/production/#{timestamp}.sql", "db/production/wordpress.sql"
    end
  end

  desc "Clear remote backup records"
  task :clear_remote_backups do
    on roles(:web) do
      execute "rm #{deploy_path}/db/backups/production/*.sql"
    end
  end

  desc 'Seed the "active" database'
  task :seed do
    on roles(:web) do
      if File.exist? 'db/active/wordpress.sql'
        execute "mkdir -p #{deploy_path}/db/"
        upload! 'db/active/wordpress.sql', "#{deploy_path}/db/wordpress.sql"
        execute "mysql -h#{db_info['production']['host']} -u#{db_info['production']['username']} -p#{db_info['production']['password']} #{db_info['production']['database']} < #{deploy_path}/db/wordpress.sql"
      end
    end
  end
end

namespace :data do
  desc "Backup data"
  task :backup do
    on roles(:web) do
      download! "#{deploy_path}/shared/public/wp-content/uploads", "./public/wp-content/", recursive: true
      download! "#{deploy_path}/shared/public/wp-content/plugins", "./public/wp-content/", recursive: true
      download! "#{deploy_path}/shared/public/wp-content/upgrade", "./public/wp-content/", recursive: true
      download! "#{deploy_path}/current/public/wp-content/themes", "./public/wp-content/", recursive: true
    end
  end

  desc "Backup data with rsync"
  task :sync_backup do
    on roles(:web) do
      puts "Syncing Backup..."
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/uploads/ ./public/wp-content/uploads/`
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/plugins/ ./public/wp-content/plugins/`
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/upgrade/ ./public/wp-content/upgrade/`
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/current/public/wp-content/themes/ ./public/wp-content/themes/`
    end
  end
end

desc 'Backup DB and remote uploads/content'
task :backup do
  invoke('db:backup')
  if disable_rsync
    invoke('data:backup')
  else
    invoke('data:sync_backup')
  end
end
