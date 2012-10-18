set :application, "kaal"

set :scm, :git
set :repository,  "git@github.com:chetanvaity/kaal.git"
set :branch, "master"
set :deploy_via, :remote_cache
set :deploy_to, "/var/www/pollengrain"
set :copy_exclude, [".git", "spec"]

set :user, "ubuntu"
ssh_options[:forward_agent] = true
ssh_options[:keys] = %w(/home/chetanv/timeline.pem) 

role :web, "pollengra.in"                          # Your HTTP server, Apache/etc
role :app, "pollengra.in"                          # This may be the same as your `Web` server
role :db,  "pollengra.in", :primary => true # This is where Rails migrations will run

set :keep_releases, 10 
# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts


# deploy internally does: deploy:update and deploy:restart
# deploy:update internally does: deploy:update_code, deploy_symlink
# We have addded more tasks below
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  # Chetan
  desc "chown the deploy_to dir to www-data"
  task :chown do
    run "#{try_sudo} chown -R www-data.www-data #{deploy_to}"
  end

  desc "Symlink shared config on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs /data/solr/data #{release_path}/solr/data"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end

  desc "Create tmpjson directory"
  task :create_tmpjson do
    run "mkdir #{release_path}/public/tmpjson"
  end

  desc "Create a dummy empty timeline.css to get rid of spurious error from within timeline-embed.js"
  task :create_dummy_timeline_css do
    run "#{try_sudo} touch #{release_path}/public/assets/timeline.css"
  end

  namespace :gems do
    desc "Install gems"
    task :install, :roles => :app do
      run "cd #{current_release} && #{try_sudo} rake gems:install"
    end
  end

  namespace :web do
    desc <<-DESC
      Present a maintenance page to visitors. Disables your application's web \
      interface by writing a "maintenance.html" file to each web server. The \
      servers must be configured to detect the presence of this file, and if \
      it is present, always display it instead of performing the request.

      By default, the maintenance page will just say the site is down for \
      "maintenance", and will be back "shortly", but you can customize the \
      page by specifying the REASON and UNTIL environment variables:

        $ cap deploy:web:disable \\
              REASON="a hardware upgrade" \\
              UNTIL="12pm Central Time"

      Further customization will require that you write your own task.
    DESC
    task :disable, :roles => :web do
      require 'erb'
        on_rollback { run "rm #{shared_path}/system/maintenance.html" }

      reason = ENV['REASON']
      deadline = ENV['UNTIL']      
      template = File.read('app/views/admin/maintenance.html.erb')
      page = ERB.new(template).result(binding)

        put page, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
  end

end

# The order here is important
# The load "deploy/assets" line adds an "after" hook to deploy:update_code
# But we want the deploy_symlink_shared to run before that
after 'deploy:setup', 'deploy:chown'
after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:symlink_shared', 'deploy:create_tmpjson'
load "deploy/assets"
after 'deploy:create_tmpjson', 'deploy:create_dummy_timeline_css'
after 'deploy:create_dummy_timeline_css', 'deploy:chown'
