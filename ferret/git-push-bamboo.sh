#!/bin/bash
source $(dirname $0)/ferret.sh

retry 5 heroku-info-create noah@heroku.com <<EOF
  heroku info --app $TARGET_APP || {
    heroku create $TARGET_APP --stack bamboo                              \
      && heroku plugins:install https://github.com/heroku/manager-cli.git \
      && heroku manager:transfer --app $TARGET_APP --to ferret
  }
EOF

retry 1 init-commit noah@heroku.com <<EOF
  git init app
  cd app
  git commit --allow-empty -m "empty"
EOF

retry 2 push noah@heroku.com <<EOF
  cd app
  git push -f git@heroku.com:$TARGET_APP.git master:test
EOF