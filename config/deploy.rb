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

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
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
  end

end

after 'deploy:setup', 'deploy:chown'
after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:symlink_shared', 'deploy:chown'
