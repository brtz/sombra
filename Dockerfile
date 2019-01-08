FROM ruby:2.6-alpine
MAINTAINER Nils Bartels <n.bartels@bigpoint.net>

ENV APP_HOME /sombra
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# https://bugs.busybox.net/show_bug.cgi?id=675
# annoyingly, let's try to remove options line from /etc/resolv.conf
RUN sed -i '/options/c\ ' /etc/resolv.conf

# on alpine we need to create www-data
RUN set -x \
    && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data

# unfortunately we need native extensions, so compilers
# we use tini (github.com/krallin/tini) as init
RUN apk add --update bash build-base linux-headers ruby-dev tini

ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/
RUN bundle install --clean

# remove apk packages again
RUN apk del --purge build-base linux-headers ruby-dev

ADD . $APP_HOME

# chown files for www-data write access. webserver needs Gemfile.lock
# Also as OpenShift changes the user, we need to allow everyone to write in $APP_HOME
RUN chown -R www-data:www-data $APP_HOME && \
    chmod -R 0777 $APP_HOME

USER www-data

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["puma", "-b", "tcp://0.0.0.0:8080"]