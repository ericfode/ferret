#!/usr/bin/env rake
require_relative "./lib/ferret.rb"
fail_fast true

require "rake/testtask"


task default: :test

Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = "./test/**/*_test.rb"
end

namespace :setup do

  task :test_env do
    bash name: :test_env, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      [ -n "$APP" ]             || { echo "error: APP required"; exit 1; }
      [ -n "$HEROKU_API_KEY" ]  || { echo "error: HEROKU_API_KEY required"; exit 1; }
      [ -n "$HEROKU_USERNAME" ] || { echo "error: HEROKU_USERNAME required"; exit 1; }
      [ -n "$ORG" ]             || { echo "error: ORG required"; exit 1; }
      [ -n "$L2MET_URL" ]       || { echo "error: L2MET_URL required"; exit 1; }
    EOF
  end

  task :install_plugins do
    bash name: :install_plugins, stdin: <<-'EOF'
      heroku plugins:install https://github.com/ddollar/heroku-anvil
      heroku plugins:install git@github.com:heroku/heroku-orgs.git
    EOF
  end

  task :update_procfile do
    bash name: :update_procfile, stdin: <<-'EOF'
      $FERRET_DIR/bin/create_proc monitors
    EOF
  end

  task :setup_user do
    bash name: :setup_user, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      unset HEROKU_API_KEY

      set -x
      heroku members:add $HEROKU_USERNAME --org $ORG --role admin
      heroku sudo labs:enable create-bamboo --user $HEROKU_USERNAME
      heroku sudo labs:enable logplex-beta-program --user $HEROKU_USERNAME
    EOF
  end

  task :deploy_services do
    Dir.foreach("#{ENV["FERRET_DIR"]}/services") do |file|
    ENV["s"] = file 
      bash name: "deploy_service-#{file}", retry:3, stdin: <<-'EOF'
        export $(cat $FERRET_DIR/.env)
        SERVICE_APP=$APP-$(basename $FERRET_DIR/$s)
        OPTS=$(cat $FERRET_DIR/$s/create.opts 2>/dev/null)
        set -x
        heroku create $SERVICE_APP --org $ORG --remote s $OPTS
        result=heroku build $FERRET_DIR/$s -r $SERVICE_APP
        git remote rm s
        $result
      EOF
      ENV["s"] = ""
    end
  end

  task :deploy_endpoints do
    2.times do |i|
      ENV["i"] = i.to_s

      bash name: "deploy_bamboo_endpoint-#{i}", retry:3, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku create --org $ORG -s bamboo $APP-bamboo-$i --remote s
        heroku build $FERRET_DIR/services/http -r $APP-bamboo-$i && heroku scale web=2 --app $APP-bamboo-$i
      EOF

      bash name: "deploy_cedar_endpoint-#{i}", retry:3, stdin: <<-'EOF'      
        heroku create --org $ORG -s cedar $APP-cedar-$i --remote s
        heroku build $FERRET_DIR/services/http -r $APP-cedar-$i && heroku scale web=2 --app $APP-cedar-$i
      EOF

      bash name: "deploy_ssl_endpoint-#{i}", retry:3, stdin: <<-'EOF'    
        heroku create --org $ORG -s cedar $APP-cedar-endpoint-$i --remote s
        success=heroku build $FERRET_DIR/services/http -r $APP-cedar-endpoint-$i&
        heroku addons:add ssl:endpoint --app $APP-cedar-endpoint-$i
        heroku domains:add www.$APP-cedar-endpoint-${i}.com --app $APP-cedar-endpoint-$i
        openssl genrsa -out server.key 2048 $> /dev/null
        openssl req -new -key server.key -out server.csr -batch -subj "/C=US/ST=CA/O=$ORG_NAME/CN=www.$APP-cedar-endpoint-${i}.com" &> /dev/null
        openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt &> /dev/null
        heroku certs:add server.crt server.key --app $APP-cedar-endpoint-$i 
        heroku scale web=2 --app $APP-cedar-endpoint-$i
        $success
      EOF
    end
  end

  task :create_run_app do
    bash name: :create_run_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku create $APP-run --org $ORG 
    EOF
  end

  task :create_addon_app do 
    bash name: :create_addon_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku create $APP-addons --org $ORG 
    EOF
  end

  task :create_monitor_app do
    bash name: :create_monitor_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)

      set -x
      heroku create $APP --org $ORG
      heroku config:set FREQ=20 APP=$APP \
      HEROKU_API_KEY=$HEROKU_API_KEY     \
      METRICS_URL=$METRICS_URL           \
      METRICS_TOKEN=$METRICS_TOKEN       \
      SPLUNK_TOKEN=$SPLUNK_TOKEN         \
      --app $APP
      heroku build $FERRET_DIR -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
    EOF
  end

  task :join_apps do
    bash name: :join_apps, stdin: <<-'EOF'
      export $(cat .env)
      unset HEROKU_API_KEY

      for APP in $(heroku list --all --org $ORG | grep "^$APP" | cut -d" " -f1); do
        heroku join --app $APP
      done
    EOF
  end

  task :add_drain do
    bash name: :add_drain, stdin: <<-'EOF'
      export $(cat .env)
      heroku drains:add $L2MET_URL --app $APP
    EOF
  end

  task :scale do
    bash name: :scale, stdin: <<-'EOF'
      $FERRET_DIR/bin/scale monitors 1
    EOF
  end
end