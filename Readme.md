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
* HEROKU_USERNAME is a unprivileged user that will be deploying ferret. We use an unprivileged user because we deploy the api key to the app and don't want sudo api keys on the platform
* HEROKU_API_KEY is the api key for the username. You can easily obtain one (if you have sudo) by running ```bin/unprivileged [email address]``` 
* ORG is the organization that the ferret is deploying to
* L2MET_URL can be obtained at [l2met](https://www.l2met.net)
* METRICS_URL is the prefix for the metrics dashboard, this should be fairly static but if it is not working ask eric@heroku.com
* METRICS_TOKEN is the api key for l2met


# Development 

```

# Run all monitors locally
foreman start

# Run monitors with increased concurrency locally
foreman start --formation="monitor_git_clone=2"

# Run a single monitor
foreman run path/to/monitor

```

## Platform Setup and Teardown

```
#Set up and run on the platform (the first time)
bin/setup

# Build and release the app if you make any changes
heroku build -r

# Scale all monitors
bin/scale [Path to monitors] [How many of each]

#Teardown ferret and all of the service apps
bin/teardown
```

## Common Tasks
```
# Push changes to ferret
heroku build -r

# Scale all monitors
bin/scale [path to monitors] [how many of each]

# Regenerate the profile
bin/create_proc [path to monitors]

# Get an unprivileged API key
bin/unprivileged [an email]
```

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
* Heroku Manager
* `heroku ps` and `heroku scale`
* HTTP Log Drains
* L2Met
* Librato
