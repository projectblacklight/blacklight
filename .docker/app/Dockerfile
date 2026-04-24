ARG ALPINE_RUBY_VERSION

FROM ruby:${ALPINE_RUBY_VERSION}-alpine

RUN apk add --update --no-cache \
  bash \
  build-base \
  git \
  libxml2-dev \
  libxslt-dev \
  libffi-dev \
  yaml-dev \
  nodejs \
  shared-mime-info \
  sqlite-dev \
  tzdata \
  yarn

RUN mkdir /app
WORKDIR /app


ENV BUNDLER_VERSION=2.5.22

RUN gem uninstall bundler -a -x --force || true \
 && gem install bundler -v ${BUNDLER_VERSION} \
 && bundle _${BUNDLER_VERSION}_ --version

# CRITICAL for alpine + arm
RUN bundle config set force_ruby_platform true

RUN gem update --system && \
  gem install bundler && \
  bundle config build.nokogiri --use-system-libraries

COPY . .

EXPOSE 3000

CMD [".docker/app/entrypoint.sh"]
