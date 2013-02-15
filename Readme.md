# Ferret - Service Monitoring as a Service

Ferret is a framework to write **monitor processes** for network **services**.

Monitor processes output structured log data for all successes and failures
against the service, from which uptime is derived. Monitor processes both run
locally and are deployed to Heroku to run continuously.

Ferret also includes tools for managing services. These are generally disposable
canary Heroku apps.

## Environment Setup

Copy env.sample to .env

* APP is the name that you want to prefix your ferret deployment.
* HEROKU_USERNAME is a unprivileged user that will be deploying ferret. We use an unprivileged user because we deploy the api key to the app and don't want sudo api keys on the platform.
* HEROKU_API_KEY is the api key for the username. You can easily obtain one (if you have sudo) by running ```bin/unprivileged [email address]``` 
* ORG is the organization that the ferret is deploying to
* L2MET_URL can be obtained at [l2met](https://www.l2met.net)
* METRICS_URL is the prefix for the metrics dashboard, this should be fairly static but if it is not working ask eric@heroku.com
* METRICS_TOKEN is the api key for l2met
* UMPIRE_API_KEY is the api key for the umpire service. You can obtain it by running ```heroku config --app umpire-production```.

## Platform Setup and Teardown

```
# Set up and run on the platform (the first time)
rake setup:all

# Teardown ferret and all of the service apps
rake teardown:all
```

## Common Tasks
```
# Build and release the app if you make any changes
rake update:all

# Only update monitor app
rake update:monitor

# Only update service apps
rake update:services

# Only update endpoint apps
rake update:endpoints

# Scale all monitors
rake util:scale
```

# Development 

```
# FIRST
bundle install

# Run all tests
rake test

# Run all monitors locally
foreman start

# Run monitors with increased concurrency locally
foreman start --formation="monitor_git_clone=2"

# Run a single monitor
foreman run path/to/monitor

```

## Tools Ferret provides
### Ferret.rb
Ferret.rb makes writing tests scripts simple, for example if you wished to run git clone in your test with retries and a timeout.

```
require './lib/ferret.rb'

bash name: :clone, timeout:120, trys: 3,  stdin: <<-'EOF'
	git clone git@github.com/heroku/ferret.git
EOF

```

This test would also produce logs for failure, success, and the length of time that it took to finish the execution of the script.

Ferret.rb also provides tools for you to repeat blocks of code.

```
require './lib/ferret.rb'
run_every_time do
	bash name: :clone, timeout:120, trys: 3,  stdin: <<-'EOF'
		git clone git@github.com/heroku/ferret.git
	EOF
end

```

If you wished for the same block of code to be run repeatedly simply add `run :forever` to the end of the file.

Running a block of code only once every few iterations of the test is also simple.

```
# 'monitors/dns/resolve'

require './lib/ferret.rb'


run_every_time do
	bash name: :curl, timeout:120, trys: 3, stdin: <<-'EOF'
		curl anaddress.amazonaws.com
	EOF
end

run_interval 5 do
	bash name: :restart, timeout:120, trys: 3,	stdin: <<-'EOF'
		heroku restart monintors_dns_resolve
	EOF
end
```
This block of code will now run once every five intervals, allowing the run_every_time block(s) to do what ever work they want to first.

The logging format is as follows

```
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 at=enter
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 status=0 measure=success
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 val=100 measure=uptime
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 at=return val=X.Y measure=time

```
`app` is defined by the `APP` env varible. `xid` is a uniquie identifier for each script, `source` is derivied from the path to the test and the name of the script (for example curl in the above scripts).

### Ferret buildpack and environment
The ferret buildpack provides the dyno with a vendord copy of the heroku client and configures it with the heroku api key in the environment.
  
### Deployment tools
The ferret deployment tools make deploying/updating/deleting fleets of service/monitor apps simple. As well as allowing you to generate procfiles from your monitors directory.

## Ferret.rb
Ferret.rb makes writing tests scripts simple, for example if you wished to run git clone in your test with retries and a timeout.

```
require './lib/ferret.rb'

bash name: :clone, timeout:120, trys: 3  stdin: <<-'EOF'
	git clone git@github.com/heroku/ferret.git
EOF

```

This test would also produce logs for failure, success, and the length of time that it took to finish the execution of the script.

Ferret.rb also provides tools for you to repeat blocks of code.

```
require './lib/ferret.rb'
run_every_time do
	bash name: :clone, timeout:120, trys: 3  stdin: <<-'EOF'
		git clone git@github.com/heroku/ferret.git
	end
EOF

```

If you wished for the same block of code to be run repeatedly simply add `run :forever` to the end of the file.

Running a block of code only once every few iterations of the test is also simple.

```
require './lib/ferret.rb'
run_interval 5 do
	bash name: :clone, timeout:120, trys: 3  stdin: <<-'EOF'
		git clone git@github.com/heroku/ferret.git
	end
EOF

```
This block of code will now run once every five intervals.
## Philosophy

Ferret is designed to easily apply the canary pattern to Heroku kernel services. Much thought should be given on how to measure properties of services in isolation.

Ferret *does not* implement complex platform integration tests, though these 
Would be easy to build with the framework.

## Platform Features

Ferret uses many of the latest features of Heroku to make the tools secure,
discoverable, configuration free, and maintenance free:

* S3
* Anvil
* Custom Buildpack (https://github.com/nzoschke/buildpack-ferret)
* Heroku Toolbelt
* Dot Profile (dot-profile-d feature)
* Heroku Orgs
* `heroku ps` and `heroku scale`
* HTTP Log Drains
* L2Met
* Librato
