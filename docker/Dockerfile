FROM ruby:2.7
MAINTAINER Glenn Y. Rolland <glenux@glenux.net>

# Setup APT proxy
COPY docker/setup-apt-proxy.sh /root/
RUN /root/setup-apt-proxy.sh 3142

# Install packages for building ruby
ENV DEBIAN_FRONTEND noninteractive
RUN echo "## Setup APT sources.list" \
 && sed -i -e '/buster-updates/d' /etc/apt/sources.list \
 && echo "## Install system dependencies" \
 && apt-get update \
 && apt-get install -q -y \
        git make wget \
        libpq-dev libpqxx-dev postgresql-client-11 postgresql-server-dev-11 \
 && echo "## Cleaning APT files" \
 && rm -rf /var/lib/apt/lists/* \
        /var/cache/apt/archives/*.deb \
        /var/cache/apt/archives/partial/*.deb \
        /var/cache/apt/*.bin

RUN useradd --create-home -s /bin/bash user

WORKDIR /home/user/app
USER user

COPY poieticgen.gemspec Gemfile.lock Gemfile /home/user/app/
COPY lib/poieticgen/version.rb /app/lib/poieticgen/version.rb
RUN gem install bundler && \
  bundle install

# ADD REMAINING (MOST OF THE) CODE
COPY . /home/user/app

# START DOCKER
EXPOSE 8000
CMD /app/docker/entrypoint.sh
