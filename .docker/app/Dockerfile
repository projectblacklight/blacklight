FROM ruby:2.6
RUN \
      wget -qO- https://deb.nodesource.com/setup_9.x | bash - && \
      wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
      echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
      apt-get update -qq && \
      apt-get install -y --force-yes --no-install-recommends \
      nodejs yarn build-essential libpq-dev
      && apt-get clean
RUN gem install bundler
RUN mkdir /app
WORKDIR /app
