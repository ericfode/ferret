#!/usr/bin/env rake
require_relative "./lib/ferret.rb"
fail_fast true

require "rake/testtask"


task default: :test

Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = "./test/**/*_test.rb"
end

namespace :teardown do

  task :all => [:ask]

  task :ask do
    out =`export $(cat $FERRET_DIR/.env); heroku list --all --org $ORG | grep "^$APP" | cut -d" " -f1`
    puts "tearing down #{out}"
    puts "is that ok (y/n)"
    get_input
  end

  task :services do
    bash name: :teardown_services, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      for APP in $(heroku list --all --org $ORG | grep "^$APP" | cut -d" " -f1); do
      (
        set -x
        heroku destroy $APP --confirm $APP
      )
      done
    EOF
  end

  task :monitor do
    bash name: :teardown_monitor, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku destroy $APP --confirm $APP
    EOF
  end

  task :endpoints do
    2.times do |i|
      ENV["i"] = i.to_s

      bash name: "teardown_endpoint_bamboo-#{i}", retry:1, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku destroy $APP-bamboo-$i --confirm $APP-bamboo-$i
      EOF

      bash name: "teardown_endpoint_cedar-#{i}", retry:1, stdin: <<-'EOF'      
        export $(cat $FERRET_DIR/.env)
        heroku destroy $APP-cedar-$i --confirm $APP-cedar-$i
      EOF

      bash name: "teardown_endpoint_ssl-#{i}", retry:1, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku destroy $APP-cedar-endpoint-$i --confirm $APP-cedar-endpoint-$i
      EOF
    end
  end  

  task :run_app do
    bash name: :teardown_run_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku destroy $APP-run --confirm $APP-run
    EOF
  end

end

namespace :update do
  task :all => [:monitor,:services,:endpoints]

  task :config do
    bash name: :update_config, stdin: <<-'EOF'
      heroku config:set                  \
      FREQ=20                            \
      APP=$APP                           \
      HEROKU_API_KEY=$HEROKU_API_KEY     \
      METRICS_URL=$METRICS_URL           \
      METRICS_TOKEN=$METRICS_TOKEN       \
      SPLUNK_TOKEN=$SPLUNK_TOKEN         \
      --app $APP
    EOF

  end

  task :procfile do
    bash name: :update_procfile, stdin: <<-'EOF'
      cd $FERRET_DIR
      TARGET_FILES=$(find monitors -type f)
      rm Procfile
      touch Procfile
      for f in $TARGET_FILES*
      do
          FERRET_NAME=$(echo $f | sed -e 's:\./::' -e 's:[/.-]:_:g')
          echo "$FERRET_NAME: $f" >> Procfile
      done
      echo "web: bundle exec thin start -p \$PORT" >> Procfile

    EOF
  end

  task :monitor => [:procfile,:config] do
    bash name: :update_monitor, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku build $FERRET_DIR -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
    EOF
  end

  task :services do
   Dir.foreach("#{ENV["FERRET_DIR"]}/services") do |file|
    ENV["s"] = file 
      bash name: "update_services-#{file}", retry:3, stdin: <<-'EOF'
        export $(cat $FERRET_DIR/.env)
        SERVICE_APP=$APP-$(basename $FERRET_DIR/$s)
        OPTS=$(cat $FERRET_DIR/$s/create.opts 2>/dev/null)
        heroku build $FERRET_DIR/$s -r $SERVICE_APP
      EOF
      ENV["s"] = ""
    end
  end

  task :endpoints do
    2.times do |i|
      ENV["i"] = i.to_s

      bash name: "update_endpoint_bamboo-#{i}", retry:3, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku build $FERRET_DIR/services/http -r $APP-bamboo-$i && heroku scale web=2 --app $APP-bamboo-$i
      EOF

      bash name: "update_endpoint_cedar-#{i}", retry:3, stdin: <<-'EOF'      
        export $(cat $FERRET_DIR/.env)
        heroku build $FERRET_DIR/services/http -r $APP-cedar-$i && heroku scale web=2 --app $APP-cedar-$i
      EOF

      bash name: "update_endpoint_ssl-#{i}", retry:3, stdin: <<-'EOF'
        export $(cat $FERRET_DIR/.env)    
        heroku build $FERRET_DIR/services/http -r $APP-cedar-endpoint-$i
      EOF
    end
  end

end

namespace :util do

  task :all =>[:join_apps,:add_drain,:scale]

  task :join_apps do
    bash name: :util_join_apps, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      unset HEROKU_API_KEY
      for APP in $(heroku list --all --org $ORG | grep "^$APP" | cut -d" " -f1); do
        heroku join --app $APP
      done
    EOF
  end

  task :add_drain do
    bash name: :util_add_drain, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      unset HEROKU_API_KEY
      heroku drains:add $L2MET_URL --app $APP
    EOF
  end

  task :scale do
    bash name: :util_scale, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      unset HEROKU_API_KEY
      cd $FERRET_DIR
      TARGET_FILES=$(find monitors -type f)
      SCALE_CMD=""
      for f in $TARGET_FILES*
      do
        FERRET_NAME=$(echo $f | sed -e 's:\./::' -e 's:[/._]:_:g')
        SCALE_CMD="$SCALE_CMD $FERRET_NAME=1"
      done
      echo $SCALE_CMD
      heroku scale $SCALE_CMD --app $APP
    EOF
  end

end


namespace :deploy do
  #addons_app is broken so is not included
  task :all => [:services,:endpoints,:monitor,:run_app,:addons_app]

  task :services do
    Dir.chdir("#{ENV["FERRET_DIR"]}/services")
    Dir["*"].each do |file|
    ENV["s"] = file 
      bash name: "deploy_service-#{file}", retry:3, stdin: <<-'EOF'
        export $(cat $FERRET_DIR/.env)
        SERVICE_APP=$APP-$(basename $FERRET_DIR/$s)
        OPTS=$(cat $FERRET_DIR/$s/create.opts 2>/dev/null)
        set -x
        heroku create $SERVICE_APP --org $ORG --remote s $OPTS
        heroku build $FERRET_DIR/$s -r $SERVICE_APP
        status=$?
        git remote rm s
        $status
      EOF
      ENV["s"] = ""
    end
  end

  task :endpoints do
    3.times do |i|
      ENV["i"] = i.to_s

      bash name: "deploy_endpoint_bamboo-#{i}", retry:3, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku create --org $ORG -s bamboo $APP-bamboo-$i --remote s
        heroku build $FERRET_DIR/services/http -r $APP-bamboo-$i && heroku scale web=2 --app $APP-bamboo-$i
      EOF

      bash name: "deploy_endpoint_cedar-#{i}", retry:3, stdin: <<-'EOF'      
        export $(cat $FERRET_DIR/.env)
        heroku create --org $ORG -s cedar $APP-cedar-$i --remote s
        heroku build $FERRET_DIR/services/http -r $APP-cedar-$i && heroku scale web=2 --app $APP-cedar-$i
      EOF

      bash name: "deploy_endpoint_ssl-#{i}", retry:3, stdin: <<-'EOF'    
        export $(cat $FERRET_DIR/.env)
        heroku create --org $ORG -s cedar $APP-cedar-endpoint-$i --remote s
        heroku addons:add ssl:endpoint --app $APP-cedar-endpoint-$i
        heroku domains:add www.$APP-cedar-endpoint-${i}.com --app $APP-cedar-endpoint-$i
        openssl genrsa -out server.key 2048 $> /dev/null
        openssl req -new -key server.key -out server.csr -batch -subj "/C=US/ST=CA/O=$ORG_NAME/CN=www.$APP-cedar-endpoint-${i}.com" &> /dev/null
        openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt &> /dev/null
        heroku certs:add server.crt server.key --app $APP-cedar-endpoint-$i 
        heroku build $FERRET_DIR/services/http -r $APP-cedar-endpoint-$i && heroku scale web=2 --app $APP-cedar-endpoint-$i
      EOF
    end
  end

  task :monitor do
    bash name: :deploy_monitor, retry:3, stdin: <<-'EOF'
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

  task :run_app do
    bash name: :deploy_run_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku create $APP-run --org $ORG 
    EOF
  end

  task :addon_app do 
    bash name: :deploy_addon_app, retry:3, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      heroku create $APP-addons --org $ORG
    EOF
  end

end

namespace :setup do

  task :all => [:test_env,:plugins,:user,"deploy:all","util:all"]

  task :test_env do
    bash name: :setup_test_env, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      [ -n "$APP" ]             || { echo "error: APP required"; exit 1; }
      [ -n "$HEROKU_API_KEY" ]  || { echo "error: HEROKU_API_KEY required"; exit 1; }
      [ -n "$HEROKU_USERNAME" ] || { echo "error: HEROKU_USERNAME required"; exit 1; }
      [ -n "$ORG" ]             || { echo "error: ORG required"; exit 1; }
      [ -n "$L2MET_URL" ]       || { echo "error: L2MET_URL required"; exit 1; }
    EOF
  end

  task :plugins do
    bash name: :setup_plugins, stdin: <<-'EOF'
      heroku plugins:install https://github.com/ddollar/heroku-anvil
      heroku plugins:install git@github.com:heroku/heroku-orgs.git
    EOF
  end

  task :user do
    bash name: :setup_user, stdin: <<-'EOF'
      export $(cat $FERRET_DIR/.env)
      unset HEROKU_API_KEY

      set -x
      heroku members:add $HEROKU_USERNAME --org $ORG --role admin
      heroku sudo labs:enable create-bamboo --user $HEROKU_USERNAME
      heroku sudo labs:enable logplex-beta-program --user $HEROKU_USERNAME
    EOF
  end
end

def get_input
  STDOUT.flush
  input = STDIN.gets.chomp
  case input.upcase
  when "Y"
    puts "going through with the task.."
    Rake::Task['teardown:services'].invoke
  when "N"
    puts "aborting the task.."
  else
    puts "Please enter Y or N"
    get_input
  end
end 