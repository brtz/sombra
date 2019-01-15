# https://bugs.busybox.net/show_bug.cgi?id=675
# that's why we stick to stretch here instead of alpine
FROM ruby:2.6-slim
MAINTAINER Nils Bartels <n.bartels@bigpoint.net>

ENV APP_HOME /sombra
ENV TINI_VERSION v0.18.0
RUN usermod -m -d $APP_HOME www-data
WORKDIR $APP_HOME

# unfortunately we need native extensions, so compilers
# we use tini (github.com/krallin/tini) as init
# install tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini
RUN apt-get update && \
    apt-get install -y bash build-essential curl file git wget

# we need libsodium for rbnacl for ED25519
ADD https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz $APP_HOME/libsodium/
WORKDIR $APP_HOME/libsodium/
RUN tar -xzf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17 && ./configure && make && make check && make install

WORKDIR $APP_HOME
ADD Gemfile $APP_HOME/
RUN chown -R www-data:www-data $APP_HOME && \
    chmod -R 0777 $APP_HOME
USER www-data

RUN bundle install --clean

# remove apk packages again
USER root
RUN rm -rf ${APP_HOME}/libsodium/
RUN apt-get remove -y --purge build-essential wget

ADD . $APP_HOME

# chown files for www-data write access. webserver needs Gemfile.lock
# Also as OpenShift changes the user, we need to allow everyone to write in $APP_HOME
RUN chown -R www-data:www-data $APP_HOME && \
    chmod -R 0777 $APP_HOME && \
    chmod -R 0777 /usr/local/bundle

USER www-data

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["puma", "-b", "tcp://0.0.0.0:8080"]
