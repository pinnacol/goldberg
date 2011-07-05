require 'bundler/capistrano'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  namespace :db do
    desc <<-DESC
      Creates the database.yml configuration file in shared path.

      By default, this task uses a template unless a template
      called database.yml.erb is found either is :template_dir
      or /config/deploy folders. The default template matches
      the template for config/database.yml file shipped with Rails.

      When this recipe is loaded, db:setup is automatically configured
      to be invoked after deploy:setup. You can skip this task setting
      the variable :skip_db_setup to true. This is especially useful
      if you are using this recipe in combination with
      capistrano-ext/multistaging to avoid multiple db:setup calls
      when running deploy:setup for all stages one by one.
    DESC
    task :setup, :except => { :no_release => true }, :roles => :app do
      default_template = <<-EOF
      base: &base
        adapter: sqlite3
        timeout: 5000
      development:
        database: #{shared_path}/db/development.sqlite3
        <<: *base
      test:
        database: #{shared_path}/db/test.sqlite3
        <<: *base
      production:
        database: #{shared_path}/db/production.sqlite3
        <<: *base
      EOF

      location = fetch(:template_dir, "config/deploy") + '/database.yml.erb'
      template = File.file?(location) ? File.read(location) : default_template

      config = ERB.new(template)

      run "mkdir -p #{shared_path}/db"
      run "mkdir -p #{shared_path}/config"
      put config.result(binding), "#{shared_path}/config/database.yml"
    end

    desc <<-DESC
      [internal] Updates the symlink for database.yml file to the just deployed release.
    DESC
    task :symlink, :except => { :no_release => true }, :roles => :app do
      run "ln -nfs #{shared_path}/config/database.yml #{current_release}/config/database.yml"
    end
  end

  namespace :mailer do
    desc <<-DESC
    DESC
    task :setup, :except => { :no_release => true }, :roles => :app do
      default_template = <<-EOF
      address: #{Capistrano::CLI.ui.ask(" SMTP Server: ")}
      port:    #{Capistrano::CLI.ui.ask("   SMTP Port: ")}
      domain:  #{Capistrano::CLI.ui.ask(" SMTP Domain: ")}
      EOF

      location = fetch(:template_dir, "config/deploy") + '/mailer.yml.erb'
      template = File.file?(location) ? File.read(location) : default_template

      config = ERB.new(template)

      run "mkdir -p #{shared_path}/config"
      put config.result(binding), "#{shared_path}/config/mailer.yml"
    end

    desc <<-DESC
      [internal] Updates the symlink for the mailer.yml file to the just deployed release.
    DESC
    task :symlink, :except => { :no_release => true }, :roles => :app do
      run "ln -nfs #{shared_path}/config/mailer.yml #{current_release}/config/mailer.yml"
    end
  end

  namespace :passenger do
    desc <<-DESC
      Restarts your application. \
      This works by creating an empty `restart.txt` file in the `tmp` folder
      as requested by Passenger server.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_release}/tmp/restart.txt"
    end

    desc <<-DESC
      Used when you have an app deployed in a subdirectory. This task will \
      create the symlink from the just deployed release to the locatsion \
      specified by the :passenger_dir variable.
    DESC
    task :symlink, :roles => :app do
      run "ln -nfs #{current_release}/public #{passenger_dir}" if fetch(:passenger_dir, false)
    end

    desc <<-DESC
      Starts the application servers. \
      Please note that this task is not supported by Passenger server.
    DESC
    task :start, :roles => :app do
      logger.info ":start task not supported by Passenger server"
    end

    desc <<-DESC
      Stops the application servers. \
      Please note that this task is not supported by Passenger server.
    DESC
    task :stop, :roles => :app do
      logger.info ":stop task not supported by Passenger server"
    end
  end

  namespace :deploy do
    desc <<-DESC
      Restarts your application. \
      Overwrites default :restart task for Passenger server.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      passenger.restart
    end

    desc <<-DESC
      Starts the application servers. \
      Overwrites default :start task for Passenger server.
    DESC
    task :start, :roles => :app do
      passenger.start
    end

    desc <<-DESC
      Stops the application servers. \
      Overwrites default :start task for Passenger server.
    DESC
    task :stop, :roles => :app do
      passenger.stop
    end
  end

  after "deploy:setup" do
    db.setup unless fetch(:skip_db_setup, false)
    mailer.setup unless fetch(:skip_mailer_setup, false)
  end

  after "deploy:finalize_update" do
    passenger.symlink
    db.symlink
    mailer.symlink
  end
end
