# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.1
FROM registry.docker.com/library/ruby:${RUBY_VERSION}-slim as base

WORKDIR /rails

# NÃO fixa RAILS_ENV aqui
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

# ------------------------
# Build stage
# ------------------------
FROM base as build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libvips \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen false
RUN bundle install && \
    rm -rf ~/.bundle/ \
      "${BUNDLE_PATH}"/ruby/*/cache \
      "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# App
COPY . .

RUN bundle exec bootsnap precompile app/ lib/

ARG PRECOMPILE_ASSETS=0
ARG ASSETS_SECRET_KEY_BASE=""

RUN if [ "$PRECOMPILE_ASSETS" = "1" ]; then \
      RAILS_ENV=production SECRET_KEY_BASE="$ASSETS_SECRET_KEY_BASE" bundle exec rails assets:clobber assets:precompile ; \
    fi

# ------------------------
# Runtime stage
# ------------------------
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libvips \
      postgresql-client \
      nodejs \
      yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

WORKDIR /rails
RUN chmod +x bin/rails

ENTRYPOINT ["sh", "-c", "rm -f tmp/pids/server.pid && exec \"$@\"", "--"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
