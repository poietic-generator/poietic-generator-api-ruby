##
## Stage I: Build gem dependencies & host-dependent libraries
##
FROM ruby:3.0 AS builder
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
        git make wget netcat-traditional gosu \
        libpq-dev libpqxx-dev postgresql-client-11 postgresql-server-dev-11 \
 && echo "## Cleaning APT files" \
 && rm -rf /var/lib/apt/lists/* \
        /var/cache/apt/archives/*.deb \
        /var/cache/apt/archives/partial/*.deb \
        /var/cache/apt/*.bin

## Add local user 'user'
RUN useradd --create-home -s /bin/bash user

## Grant him·her sudo privileges
# RUN echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
#    chmod 0440 /etc/sudoers.d/user

## Switch to user for bundle & directory setup
USER user
WORKDIR /home/user/app

COPY --chown=user poieticgen.gemspec Gemfile.lock Gemfile /home/user/app/
COPY --chown=user lib/poieticgen/version.rb /home/user/app/lib/poieticgen/version.rb
RUN gem install bundler \
 && bundle install

## Add most of the code
COPY --chown=user . /home/user/app

##
## Stage II : Runtime for app
## 
FROM builder AS runtime

EXPOSE 3000
VOLUME /home/user/app/tmp

# Repass root
USER root
ENTRYPOINT ["/home/user/app/docker/entrypoint.sh"]
CMD ["/home/user/app/docker/run.sh"]

