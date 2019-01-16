# https://bugs.busybox.net/show_bug.cgi?id=675
# that's why we stick to stretch here instead of alpine
FROM ruby:2.6-slim
MAINTAINER Nils Bartels <nils@bartels.xyz>

ENV APP_HOME /sombra
ENV TINI_VERSION v0.18.0
RUN usermod -m -d $APP_HOME www-data
WORKDIR $APP_HOME

# unfortunately we need native extensions, so compilers
# we use tini (github.com/krallin/tini) as init
# install tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini
RUN echo "deb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/strech-backports.list
RUN apt-get update && \
    apt-get install -y bash build-essential curl file git nano wget && \
    apt-get -t stretch-backports -y install libsodium-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR $APP_HOME
ADD Gemfile $APP_HOME/

RUN bundle install --clean --jobs=4

# remove apk packages again
RUN rm -rf ${APP_HOME}/libsodium/
RUN apt-get remove -y --purge build-essential wget

ADD . $APP_HOME

# chown files for www-data write access. webserver needs Gemfile.lock
# Also as OpenShift changes the user, we need to allow everyone to write in $APP_HOME
RUN chown -R www-data:root $APP_HOME && \
    chmod -R g=u $APP_HOME

USER www-data

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["puma", "-b", "tcp://0.0.0.0:8080"]
