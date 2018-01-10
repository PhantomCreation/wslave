require 'yaml'
require 'date'

opts = YAML.load_file('config/definitions.yml')
db_info = YAML.load_file('config/database.yml')

deploy_user = opts['deployer']['user']
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

  desc 'Finds and replaces localhost:8000 and your Staging address with the Production address'
  task :chikan do
    on roles(:web) do
      puts 'Replacing localhost:8000 and Production URLs with Staging URLs...'

      # Create a backup, download it, and remove remote copy
      execute "mkdir -p #{deploy_path}/db/tmp"
      execute "mysqldump --opt --user=#{db_info['staging']['username']} --password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} #{db_info['staging']['database']} > #{deploy_path}/db/tmp/wordpress.sql"
      FileUtils.mkdir_p('./db/tmp') unless Dir.exist?('./db/tmp')
      download! "#{deploy_path}/db/tmp/wordpress.sql", "db/tmp/wordpress.sql"
      execute "rm #{deploy_path}/db/tmp/*.sql"

      # Regex replace in file
      db_data = File.read('db/tmp/wordpress.sql')

      db_data = db_data.gsub(/localhost:8000/, "#{opts['deployer']['fqdn']['staging']}")
      if opts['deployer']['fqdn']['production'] != ''
        db_data = db_data.gsub(/#{opts['deployer']['fqdn']['production']}/, "#{opts['deployer']['fqdn']['staging']}")
      end

      File.open('db/tmp/wordpress.sql', "w") {|file| file.puts db_data }

      # Upload file
      upload! 'db/tmp/wordpress.sql', "#{deploy_path}/db/tmp/wordpress.sql"
      execute "mysql -h#{db_info['staging']['host']} -u#{db_info['staging']['username']} -p#{db_info['staging']['password']} #{db_info['staging']['database']} < #{deploy_path}/db/tmp/wordpress.sql"
      execute "rm #{deploy_path}/db/tmp/*.sql"
      `rm db/tmp/wordpress.sql`

     # cmd_head = "mysql -h#{db_info['production']['host']} -u#{db_info['production']['username']} -p#{db_info['production']['password']} #{db_info['production']['database']}"

     # tables_x_fields = [
     #   ['wp_commentmeta',   'meta_value'],
     #   ['wp_comments',      'comment_content'],
     #   ['wp_links',         'link_description'],
     #   ['wp_options',       'option_value'],
     #   ['wp_postmeta',      'meta_value'],
     #   ['wp_posts',         'post_content'],
     #   ['wp_posts',         'post_title'],
     #   ['wp_posts',         'post_excerpt'],
     #   ['wp_term_taxonomy', 'description'],
     #   ['wp_usermeta',      'meta_value']
     # ]

     # # For localhost:8000 entries
     # tables_x_fields.each do |tf|
     #   execute "#{cmd_head} -e \"UPDATE #{tf[0]} SET #{tf[1]} = REPLACE(#{tf[1]}, 'localhost:8000', '#{site_fqdn}')\""
     # end

     # # For staging entires
     # staging_addr = opts['deployer']['fqdn']['staging'].strip
     # if staging_addr != ''
     #   #excute "#{cmd_head} -c UPDATE #{tf.first} SET #{tf.second} = REPLACE(#{tf.second}, '', '#{site_fqdn}')"
     # end
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
    end
  end

  desc 'Clear out remote DB tables and delete all remote files in deploy target directory'
  task :destruct do
    on roles(:web) do
      execute "mysqldump --opt --user=#{db_info['staging']['username']} " \
        "--password=#{db_info['staging']['password']} --host=#{db_info['staging']['host']} " \
        "--add-drop-table --no-data #{db_info['staging']['database']} | " \
        "grep -e '^DROP \| FOREIGN_KEY_CHECKS' | mysql -u#{db_info['staging']['username']} " \
        "-p#{db_info['staging']['password']} -h#{db_info['staging']['host']} " \
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
    end
  end

  desc "Backup data with rsync"
  task :sync_backup do
    on roles(:web) do
      puts "Syncing Backup..."
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/uploads/ ./public/wp-content/uploads/`
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/plugins/ ./public/wp-content/plugins/`
      `rsync -avzPhu --delete #{deploy_user}@#{host_addr}:#{deploy_path}/shared/public/wp-content/upgrade/ ./public/wp-content/upgrade/`
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
