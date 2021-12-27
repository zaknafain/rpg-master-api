FROM ruby:3.1.0-alpine3.12

# Minimal requirements to run a Rails app
RUN apk add --no-cache --update build-base=0.5-r2 \
                                linux-headers=5.4.5-r1 \
                                tzdata=2020c-r1 \
                                postgresql-dev=12.5-r0 \
                                libpq=12.5-r0

ENV BUNDLE_PATH=/bundle/ruby-${RUBY_VERSION} \
    BUNDLE_BIN=/bundle/ruby-${RUBY_VERSION}/bin \
    GEM_HOME=/bundle/ruby-${RUBY_VERSION} \
    BUNDLE_CACHE_PATH=/bundle/ruby-${RUBY_VERSION}/cache
ENV PATH="${BUNDLE_BIN}:${PATH}"

WORKDIR /rpg-master-api
COPY Gemfile ./Gemfile
COPY Gemfile.lock ./Gemfile.lock

RUN gem install bundler:2.1.4
RUN bundle install

EXPOSE 3000

COPY docker-entrypoint.sh /opt/rpg-master-api/docker-entrypoint.sh
ENTRYPOINT ["/opt/rpg-master-api/docker-entrypoint.sh"]
