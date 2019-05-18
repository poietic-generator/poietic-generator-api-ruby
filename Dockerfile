FROM ruby:2.5
MAINTAINER Glenn Y. Rolland <glenux@glenux.net>

# Install packages for building ruby
ENV DEBIAN_FRONTEND noninteractive
RUN sed -i -e '/jessie-updates/d' /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -q -y \
		git build-essential \
 		make wget \
 		libpq-dev postgresql-client postgresql-server-dev-9.6 \
 	&& rm -rf /var/lib/apt/lists/* \
 		/var/cache/apt/archives/*.deb \
 		/var/cache/apt/archives/partial/*.deb \
 		/var/cache/apt/*.bin

WORKDIR /app
ADD poieticgen.gemspec Gemfile.lock Gemfile /app/
ADD lib/poieticgen/version.rb /app/lib/poieticgen/version.rb
RUN gem install bundler && \
	bundle install --path /app-cache

# ADD REMAINING (MOST OF THE) CODE
ADD . /app

# START DOCKER
EXPOSE 8000
CMD /app/docker/entrypoint.sh
