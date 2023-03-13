ARG RUBY_VERSION=3.1.2

FROM ruby:${RUBY_VERSION}-alpine3.16 AS build

# Minimal requirements to run a Rails app

RUN apk update && \
    apk add --no-cache --update \
      build-base~=0.5 \
      linux-headers~=5.16.7 \
      tzdata~=2022 \
      git~=2.36 \
      postgresql14-dev~=14 \
      libpq~=14

ENV BUNDLE_PATH=/bundle/ruby-${RUBY_VERSION} \
    BUNDLE_BIN=/bundle/ruby-${RUBY_VERSION}/bin \
    GEM_HOME=/bundle/ruby-${RUBY_VERSION} \
    BUNDLE_CACHE_PATH=/bundle/ruby-${RUBY_VERSION}/cache
ENV PATH="${BUNDLE_BIN}:${PATH}"

WORKDIR /rpg-master-api
COPY Gemfile ./Gemfile
COPY Gemfile.lock ./Gemfile.lock

RUN gem install bundler:2.3.24

FROM build AS production

EXPOSE 3000

RUN bundle config set --local without test development && \
    bundle install

COPY . .

COPY docker-entrypoint.sh /opt/rpg-master-api/docker-entrypoint.sh
ENTRYPOINT ["/opt/rpg-master-api/docker-entrypoint.sh"]

FROM build AS test

RUN bundle config set --local without development && \
    bundle install

COPY . .

FROM build AS development

EXPOSE 3000

RUN bundle config set --local without test && \
    bundle install

COPY . .

COPY docker-entrypoint.sh /opt/rpg-master-api/docker-entrypoint.sh
ENTRYPOINT ["/opt/rpg-master-api/docker-entrypoint.sh"]
