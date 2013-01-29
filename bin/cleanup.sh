#!/bin/bash
heroku list --all --org "ferret-dev" | grep "ferret" | xargs -I {} heroku sudo apps:delete {} --confirm {}
