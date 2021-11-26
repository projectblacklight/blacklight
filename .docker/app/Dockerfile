ARG ALPINE_RUBY_VERSION

FROM ruby:${ALPINE_RUBY_VERSION}-alpine

RUN apk add --update --no-cache \
  bash \
  build-base \
  git \
  libxml2-dev \
  libxslt-dev \
  nodejs \
  shared-mime-info \
  sqlite-dev \
  tzdata \
  yarn

RUN mkdir /app
WORKDIR /app

RUN gem update --system && \
  gem install bundler && \
  bundle config build.nokogiri --use-system-libraries

COPY . .

EXPOSE 3000

CMD [".docker/app/entrypoint.sh"]
