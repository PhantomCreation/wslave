require 'yaml'
require 'date'

opts = YAML.load_file('config/definitions.yml')
db_info = YAML.load_file('config/database.yml')

deploy_user = opts['deployer']['user']
deploy_group = opts['deployer']['www_data_group']
host_addr = opts['deployer']['host']['staging']
multisite_root = opts['deployer']['root']
site_fqdn = opts['deployer']['fqdn']['staging']

disable_rsync = (opts.include?('options') && opts['options'].include?('rsync_enabled') && 
          opts['options']['rsync_enabled'] == false)

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
      require_relative '../deploy-tools/gen-wp-config'
      FileUtils.mkdir('./tmp') unless Dir.exist?('./tmp')
      GenerateWPConfig('staging', './tmp')
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

  desc 'Finds and replaces localhost:8000 and your Production address with the Staging address'
  task :chikan do
    on roles(:web) do
      puts 'Replacing localhost:8000 and Production URLs with Staging URLs...'

      # Set an anchor to first homogonize instances of URL's, then replace all the anchors
      anchor = "URL_REPLACEMENT_ANCHOR_00000"

      # Create a backup, download it, and remove remote copy
      execute "mkdir -p #{deploy_path}/db/tmp"
      execute "mysqldump --opt --user=#{db_info['staging']['username']} --password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} #{db_info['staging']['database']} > #{deploy_path}/db/tmp/wordpress.sql"
      FileUtils.mkdir_p('./db/tmp') unless Dir.exist?('./db/tmp')
      download! "#{deploy_path}/db/tmp/wordpress.sql", "db/tmp/wordpress.sql"
      execute "rm #{deploy_path}/db/tmp/*.sql"

      # Regex replace in file
      db_data = File.read('db/tmp/wordpress.sql')

      # This may seem roundabout, but in order to avoid mangling the target URL we need to first
      # replace instances of it with something that won't match
      db_data = db_data.gsub(/#{opts['deployer']['fqdn']['staging']}/, anchor)

      # Set production URL's to the anchor
      if opts['deployer']['fqdn']['production'] != ''
        db_data = db_data.gsub(/#{opts['deployer']['fqdn']['production']}/, anchor)
      end

      # Set localhost entries to the anchor
      db_data = db_data.gsub(/localhost\%3A8000/, anchor)
      db_data = db_data.gsub(/localhost:8000/, anchor)

      # Replace anchors with the correct target URL
      db_data = db_data.gsub(anchor, "#{opts['deployer']['fqdn']['staging']}")

      # Save results
      File.open('db/tmp/wordpress.sql', "w") {|file| file.puts db_data }

      # Upload file and seed
      upload! 'db/tmp/wordpress.sql', "#{deploy_path}/db/tmp/wordpress.sql"
      execute "mysql -h#{db_info['staging']['host']} -u#{db_info['staging']['username']} -p#{db_info['staging']['password']} #{db_info['staging']['database']} < #{deploy_path}/db/tmp/wordpress.sql"
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
      else
        invoke('deploy:sync_wp')
        invoke('deploy:sync_plugins')
        invoke('deploy:sync_uploads')
      end
      invoke('deploy')
      invoke('db:seed')
      invoke('deploy:chikan')
      invoke('deploy:set_permissions')
    end
  end

  desc 'Clear out remote DB tables and delete all remote files in deploy target directory'
  task :destruct do
    on roles(:web) do
      execute "mysql --user=#{db_info['staging']['username']} " \
        "--password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} " \
        "-Nse 'show tables' #{db_info['staging']['database']} | " \
        "while read table; do echo \"drop table $table;\"; done | " \
        "mysql --user=#{db_info['staging']['username']} " \
        "--password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} " \
        "#{db_info['staging']['database']}"

      execute "rm -rf #{deploy_path}/*"
    end
  end
end

namespace :db do
  desc "Backup DB"
  task :backup do
    on roles(:web) do
      timestamp = DateTime.now
      execute "mkdir -p #{deploy_path}/db/backups/staging/"
      execute "mysqldump --opt --user=#{db_info['staging']['username']} --password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} #{db_info['staging']['database']} > #{deploy_path}/db/backups/staging/#{timestamp}.sql"
      FileUtils.mkdir_p('./db/staging') unless Dir.exist?('./db/staging')
      download! "#{deploy_path}/db/backups/staging/#{timestamp}.sql", "db/staging/wordpress.sql"
    end
  end

  desc "Clear remote backup records"
  task :clear_remote_backups do
    on roles(:web) do
      execute "rm #{deploy_path}/db/backups/staging/*.sql"
    end
  end

  desc 'Seed the "active" database'
  task :seed do
    on roles(:web) do
      if File.exist? 'db/active/wordpress.sql'
        execute "mkdir -p #{deploy_path}/db/"
        upload! 'db/active/wordpress.sql', "#{deploy_path}/db/wordpress.sql"
        execute "mysql -h#{db_info['staging']['host']} -u#{db_info['staging']['username']} -p#{db_info['staging']['password']} #{db_info['staging']['database']} < #{deploy_path}/db/wordpress.sql"
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
