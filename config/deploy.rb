$:.unshift(File.expand_path('./lib', ENV['rvm_path']))  # Add RVM's lib directory to the load path.
require "rvm/capistrano"                                # Load RVM's capistrano plugin.

require 'lib/capistrano_extras'

default_run_options[:pty] = true

set :application, "goldberg"
set :repository,  "git://github.com/c42/goldberg.git"
set :deploy_to,   "/var/www/rails-apps/#{application}"
set :branch,      "master"
set :use_sudo,    false
set :user,        "rails"

set :scm, :git
set :git_enable_submodules, 1

role :web, "panda"                          # Your HTTP server, Apache/etc
role :app, "panda"                          # This may be the same as your `Web` server
role :db,  "panda", :primary => true        # This is where Rails migrations will run

namespace :app do
end

after "bundle:install" do
end

after "deploy" do
  deploy.cleanup
end
