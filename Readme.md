# Ferret - Service Monitoring as a Service

Ferret is a framework to write **monitor processes** for network **services**.

Monitor processes output structured log data for all successes and failures
against the service, from which uptime is derived. Monitor processes both run
locally and are deployed to Heroku to run continuously.

Ferret also includes tools for managing services. These are generally disposable
canary Heroku apps.

## Development Setup

Edit env.sample and fill in HEROKU_USERNAME with your unpriveledged @gmail.com
Heroku account as well as HEROKU_API_KEY with an unpriveleged api key, L2MET_URL
with the drain you want to use, and METRICS_TOKEN with your l2met token (
the first part of the L2MET_URL), and APP_NAME with what you want your ferret
deploy to be named.

```bash

# Run all monitors locally
foreman start

# Run monitors with increased concurrency locally
foreman start --formation="monitor_git_clone=2"

```

## Platform Setup

```bash
#Set up and run on the platform (the first time)
bin/setup

# Build and release the app if you make any changes
heroku build -r

# Scale all monitors
bin/scale.sh [Path to monitors] [How many of each]

#Teardown ferret and all of the service apps
bin/teardown
```

## Philosophy

Ferret is designed to easily apply the canary pattern to Heroku kernel services.
Much thought should be given on how to measure properties of services in
isolation.

Ferret *does not* implement complex platform integration tests, though these 
would be easy to build with the framework.

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
