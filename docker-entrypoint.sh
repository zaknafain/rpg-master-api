#!/usr/bin/env sh

# if RAILS_ENV was NOT set before then default to development
[ -z "$RAILS_ENV" ] && export RAILS_ENV=development

# Symlink the log file to stdout for Docker
echo "⚰  Symlinking to /code/log/$RAILS_ENV.log"
ln -sf /dev/stdout /rpg-master-api/log/$RAILS_ENV.log

echo "🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖 $RAILS_ENV 🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖"

if [ "$RAILS_ENV" = 'development' ]; then
  ###############
  # DEVELOPMENT #
  ###############

  bundle install
  bundle exec rake db:create db:migrate
  bundle exec puma -p "${PORT:-3000}" -e "${RAILS_ENV:-development}" -w "${WEB_CONCURRENCY:-1}" -t "${RAILS_MAX_THREADS:-1}:${RAILS_MAX_THREADS:-1}"
  exec "$@" # Finally call command issued to the docker service (if any)
elif [ "$RAILS_ENV" = 'production' ]; then
  ##############
  # PRODUCTION #
  ##############

  if [ "$1" = '' ]; then
      bundle exec rake db:create db:migrate
      bundle exec puma -p "${PORT:-3000}" -e "${RAILS_ENV:-production}" -w "${WEB_CONCURRENCY:-1}" -t "${RAILS_MAX_THREADS:-1}:${RAILS_MAX_THREADS:-1}"
  else
    exec "$@" # Finally call command issued to the docker service (if any)
  fi
fi
