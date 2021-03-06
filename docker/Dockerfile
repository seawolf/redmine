FROM ruby:2.6-alpine3.13

# explicitly set uid/gid to guarantee that it won't change in the future
# the values 999:999 are identical to the current user/group id assigned
# alpine already has a gid 999, so we'll use the next id
RUN addgroup -S -g 1000 redmine && adduser -S -H -G redmine -u 999 redmine

RUN set -eux; \
	apk add --no-cache \
		bash \
		ca-certificates \
		su-exec \
		tini \
		tzdata \
		wget \
		\
		openssh-client \
		git \
		mercurial \
		subversion \
		\
# we need "gsfonts" for generating PNGs of Gantt charts
# and "ghostscript" for creating PDF thumbnails (in 4.1+)
		ghostscript \
		ghostscript-fonts \
    pkgconfig imagemagick6 imagemagick6-dev imagemagick6-libs \
	;

ENV RAILS_PORT 3000
ENV RAILS_ENV production
WORKDIR /usr/src/redmine

# https://github.com/docker-library/redmine/issues/138#issuecomment-438834176
# (bundler needs this for running as an arbitrary user)
ENV HOME /home/redmine
RUN set -eux; \
	[ ! -d "$HOME" ]; \
	mkdir -p "$HOME"; \
	chown redmine:redmine "$HOME"; \
	chmod 1777 "$HOME"

ENV REDMINE_VERSION 4.2-stable-seawolf

RUN set -eux; \
	wget -O redmine.tar.gz "https://github.com/seawolf/redmine/archive/$REDMINE_VERSION.tar.gz" ; \
	tar -xf redmine.tar.gz --strip-components=1; \
	rm redmine.tar.gz files/delete.me log/delete.me; \
	mkdir -p log public/plugin_assets sqlite tmp/pdf tmp/pids; \
	chown -R redmine:redmine ./; \
# log to STDOUT (https://github.com/docker-library/redmine/issues/108)
	echo 'config.logger = Logger.new(STDOUT)' > config/additional_environment.rb; \
# fix permissions for running as an arbitrary user
	chmod -R ugo=rwX config db sqlite; \
	find log tmp -type d -exec chmod 1777 '{}' +

COPY Gemfile.local Gemfile.local

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		freetds-dev \
		gcc \
		make \
		musl-dev \
		patch \
		sqlite-dev \
		ttf2ufm \
		zlib-dev \
	; \
	\
	su-exec redmine bundle install --jobs "$(nproc)" --without development test; \
	# for adapter in mysql2 postgresql sqlserver sqlite3; do \
	for adapter in sqlite3; do \
		echo "$RAILS_ENV:" > ./config/database.yml; \
		echo "  adapter: $adapter" >> ./config/database.yml; \
		su-exec redmine bundle install --jobs "$(nproc)" --without development test; \
		cp Gemfile.lock "Gemfile.lock.${adapter}"; \
	done; \
	rm ./config/database.yml; \
# fix permissions for running as an arbitrary user
	chmod -R ugo=rwX Gemfile.lock "$GEM_HOME"; \
# this requires coreutils because "chmod +X" in busybox will remove +x on files (and coreutils leaves files alone with +X)
	rm -rf ~redmine/.bundle; \
	\
# https://github.com/naitoh/rbpdf/issues/31
	rm /usr/local/bundle/gems/rbpdf-font-1.19.*/lib/fonts/ttf2ufm/ttf2ufm; \
	\
    apk add --no-cache --virtual .redmine-rundeps \
      libc6-compat \
      # so:libdl.so.2 \
      sqlite-dev \
    ; apk del --no-network .build-deps

	# runDeps="$( \
	# 	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/bundle/gems \
	# 	| tr ',' '\n' \
	# 	| sort -u \
	# 	| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	# )"; \
	# apk add --no-network --virtual .redmine-rundeps $runDeps; \
	# apk del --no-network .build-deps

VOLUME /usr/src/redmine/config
VOLUME /usr/src/redmine/files
VOLUME /usr/src/redmine/plugins
VOLUME /usr/src/redmine/public/themes
VOLUME /usr/src/redmine/sqlite

COPY docker/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE $RAILS_PORT
CMD ["rails", "server", "-b", "0.0.0.0"]
