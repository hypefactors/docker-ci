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

# INSTALL
RUN apt-get update \
    && apt-get install -y apt-utils curl unzip git software-properties-common

# Puppeteer dependencies
RUN apt-get update \
    && apt-get install -y gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 \
    libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 \
    libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 \
    libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 \
    lsb-release xdg-utils wget

# PHP 7.1
RUN add-apt-repository -y ppa:ondrej/php && apt-get update \
    && apt-get install -y libmcrypt-dev libpq-dev libpng-dev php-pear \
       php7.1-dev php7.1-fpm php7.1-cli php7.1-mcrypt php7.1-gd php7.1-memcached \
       php7.1-mysql php7.1-pgsql php7.1-sqlite3 php7.1-imap php7.1-mbstring \       
       php7.1-json php7.1-curl php7.1-gd php7.1-gmp php7.1-zip php-redis php7.1-xml \
       php-xdebug \
    && pecl install mongodb \
    && echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` \
    && phpenmod mcrypt \
    && mkdir /run/php

# Composer
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer

# MySQL
RUN apt-get update && apt-get install -y mysql-client mysql-server

# Node.js v9
RUN curl --silent --location https://deb.nodesource.com/setup_9.x | bash - \
    && apt-get install nodejs -y

# Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    apt-get update && \
    apt-get install -y dbus-x11 google-chrome-stable

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Cypress.js dependencies
RUN apt-get update && \
    apt-get install -y libgtk2.0-0 libnotify-dev libgconf-2-4 \
    libnss3 libxss1 libasound2 xvfb

# Copy configuration scripts
ADD config /config

# Install Goss
RUN curl -fsSL https://goss.rocks/install | sh

# Cleanup for smaller image size
RUN apt-get remove -y --purge apt-utils software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
