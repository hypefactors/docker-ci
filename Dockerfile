# to get docker, on which circleci is dependent
FROM docker:17.12.0-ce as static-docker-source

FROM ubuntu:16.04
LABEL maintainer="Hypefactors"

ENV DEBIAN_FRONTEND noninteractive

ENV LANG C.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL C.UTF-8
# good colors for most applications
ENV TERM xterm
# avoid million NPM install messages
ENV npm_config_loglevel warn 
# allow installing when the main user is root
ENV npm_config_unsafe_perm true
# 
ENV CLOUD_SDK_VERSION 200.0.0

# INSTALL
RUN apt-get update \
    && apt-get install -y apt-utils curl unzip git software-properties-common lsb-release

# PHP 7.2
RUN add-apt-repository -y ppa:ondrej/php && apt-get update \
    && apt-get install -y libpq-dev libpng-dev php-pear \
       php7.2-dev php7.2-fpm php7.2-cli php7.2-gd \
       php7.2-mysql php7.2-sqlite3 php7.2-imap php7.2-mbstring \       
       php7.2-json php7.2-curl php7.2-gd php7.2-gmp php7.2-zip php-redis php7.2-xml \
       php-yaml php-mongodb \ 
    && mkdir /run/php

# Composer
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer

# MySQL
RUN apt-get update && apt-get install -y mysql-client 

# Node.js v9
RUN curl --silent --location https://deb.nodesource.com/setup_9.x | bash - \
    && apt-get install nodejs -y

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Cypress.js dependencies
RUN apt-get update && \
    apt-get install -y libgtk2.0-0 libnotify-dev libgconf-2-4 \
    libnss3 libxss1 libasound2 xvfb

# Copy configuration scripts
ADD config /config

# Google Cloud SDK
# copied from https://hub.docker.com/r/google/cloud-sdk/~/dockerfile/
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image 

# Cloud SQL Proxy
ADD https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 /usr/local/bin/cloud_sql_proxy
RUN chmod +x /usr/local/bin/cloud_sql_proxy

# CircleCI
COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
ADD https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci /usr/local/bin/circleci
RUN chmod +x /usr/local/bin/circleci

# Lokalise
ADD https://s3-eu-west-1.amazonaws.com/lokalise-assets/cli/lokalise-0.581-linux-amd64.tgz /tmp
RUN cd tmp && tar xvfz lokalise*.tgz && mv /tmp/lokalise /usr/local/bin

# Install Goss
RUN curl -fsSL https://goss.rocks/install | sh

# Node.js v9
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \ 
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install yarn



# Cleanup for smaller image size
RUN apt-get remove -y --purge apt-utils software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
