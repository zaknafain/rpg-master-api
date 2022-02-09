FROM ruby:3.0.3-alpine3.15

# Minimal requirements to run a Rails app
RUN apk add --no-cache --update build-base=0.5-r2 \
                                linux-headers=5.10.41-r0 \
                                tzdata=2021e-r0 \
                                postgresql14-dev=14.1-r5 \
                                libpq=14.1-r5

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
