FROM ruby:2.3
MAINTAINER Glenn Y. Rolland <glenux@glenux.net>

# Install packages for building ruby
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get install -q -y \
      git build-essential make wget gosu \
      libpq-dev postgresql-client postgresql-server-dev-all

# Install packages for websockets
# RUN wget https://github.com/joewalnes/websocketd/releases/download/v0.2.12/websocketd-0.2.12_amd64.deb && \
#	dpkg -i *.deb && \
#	rm *.deb

RUN gem install bundler

RUN useradd -m user -d /app \
 && mkdir -p /app.cache /app.bundle \
 && cd /app.cache \
 && git init \
 && chown -R user:user /app /app.cache /app.bundle

COPY --chown=user lib/poieticgen/version.rb /app.cache/lib/poieticgen/version.rb
COPY --chown=user poieticgen.gemspec /app.cache/poieticgen.gemspec
COPY --chown=user Gemfile.lock /app.cache/Gemfile.lock
COPY --chown=user Gemfile /app.cache/Gemfile

# PRE-INSTALL DEPENDENCIES

ENV BUNDLE_PATH /app.bundle
ENV BUNDLE_APP_CONFIG /app.cache

WORKDIR /app.cache
USER user
RUN echo "Installing gems ... " \
 && bundle config \
 && bundle install 

# ADD REMAINING (MOST OF THE) CODE
COPY --chown=user . /app/

# START CONTAINER
USER user
EXPOSE 8000
WORKDIR /app/
CMD /app/misc/docker-start-postgres.sh

