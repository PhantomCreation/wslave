require 'yaml'

opts = YAML.load_file('config/definitions.yml')
db_info = YAML.load_file('config/database.yml')

deploy_user = opts['deployer']['user']
host_addr = opts['deployer']['host']['production']
multisite_root = opts['deployer']['root']
site_fqdn = opts['deployer']['fqdn']['production']

role :web, "#{deploy_user}@#{host_addr}" 

set :tmp_dir, "#{multisite_root}/tmp"
deploy_path = "#{multisite_root}/#{site_fqdn}"

set :linked_dirs, %w{public/wp-content/uploads public/wordpress public/wp-content/upgrade public/wp-content/plugins tmp}
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

  desc 'Perform special seed tasks required on intial seed'
  task :initial do
    on roles(:web) do
      invoke!('deploy:check:directories')
      invoke!('deploy:check:linked_dirs')
      invoke!('deploy:check:make_linked_dirs')
      invoke('deploy:wp_config')
      if (opts.include?('options') && opts['options'].include?('rsync_enabled') && 
          opts['options']['rsync_enabled'] == false)
        invoke('deploy:upload_wp')
        invoke('deploy:upload_plugins')
        invoke('deploy:upload_uploads')
      else
        invoke('deploy:sync_wp')
        invoke('deploy:sync_plugins')
        invoke('deploy:sync_uploads')
      end
      invoke('deploy')
      invoke('db:seed')
    end
  end

  desc 'Clear out remote DB tables and delete all remote files in deploy target directory'
  task :destruct do
    on roles(:web) do
      execute "mysqldump --opt --user=#{db_info['production']['username']} " \
        "--password=#{db_info['production']['password']} --host=#{db_info['production']['host']} " \
        "--add-drop-table --no-data #{db_info['production']['database']} | " \
        "grep -e '^DROP \| FOREIGN_KEY_CHECKS' | mysql -u#{db_info['production']['username']} " \
        "-p#{db_info['production']['password']} -h#{db_info['production']['host']} " \
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
    end
  end
end

desc 'Backup DB and remote uploads/content'
task :backup do
  invoke('db:backup')
  invoke('data:backup')
end
