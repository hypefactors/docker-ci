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
ENV CLOUD_SDK_VERSION 198.0.0

# INSTALL
RUN apt-get update \
    && apt-get install -y apt-utils curl unzip git software-properties-common

# PHP 7.1
RUN add-apt-repository -y ppa:ondrej/php && apt-get update \
    && apt-get install -y libmcrypt-dev libpq-dev libpng-dev php-pear \
       php7.1-dev php7.1-fpm php7.1-cli php7.1-mcrypt php7.1-gd php7.1-memcached \
       php7.1-mysql php7.1-pgsql php7.1-sqlite3 php7.1-imap php7.1-mbstring \       
       php7.1-json php7.1-curl php7.1-gd php7.1-gmp php7.1-zip php-redis php7.1-xml \
    && pecl install mongodb \
    && echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` \
    && phpenmod mcrypt \
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
RUN apt-get -qqy update && apt-get install -qqy \
        curl \
        gcc \
        python-dev \
        python-setuptools \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
    && easy_install -U pip && \
    pip install -U crcmod   && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-java=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-go=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datalab=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datastore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-pubsub-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-bigtable-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-cbt=${CLOUD_SDK_VERSION}-0 \
        kubectl && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image 

# Cloud SQL Proxy
ADD https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 /usr/local/bin/cloud_sql_proxy
RUN chmod +x /usr/local/bin/cloud_sql_proxy

# Install Goss
RUN curl -fsSL https://goss.rocks/install | sh

# Cleanup for smaller image size
RUN apt-get remove -y --purge apt-utils software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
