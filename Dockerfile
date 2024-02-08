# to get docker, on which circleci is dependent
FROM docker:17.12.0-ce as static-docker-source

FROM ubuntu:20.04

LABEL maintainer="support@hypefactors.com"

# Avoid prompts while building
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# avoid million NPM install messages
ENV npm_config_loglevel=warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm=true

ENV DOCKERIZE_VERSION=v0.6.1

# Install required dependencies
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y \
        ca-certificates \
        curl \
        git \
        gnupg \
        unzip \
        wget \
        # Cypress related
        libgtk2.0-0 \
        libnotify-dev \
        libgconf-2-4 \
        libnss3 \
        libxss1 \
        libasound2 \
        xvfb \
        snapd

# Setup GnuPG
RUN mkdir -p ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C

# Install and setup PHP
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update -y \
    && apt-get install -y --only-upgrade libpcre2-8-0 \
    && apt-get install -y --no-install-recommends \
        php8.1-cli \
        php8.1-fpm \
        php8.1-apcu \
        php8.1-bcmath \
        php8.1-bz2 \
        php8.1-ctype \
        php8.1-curl \
        php8.1-fileinfo \
        php8.1-gd \
        php8.1-gmp \
        php8.1-igbinary \
        php8.1-imap \
        php8.1-intl \
        php8.1-mbstring \
        php8.1-msgpack \
        php8.1-mysql \
        php8.1-readline \
        php8.1-redis \
        php8.1-soap \
        php8.1-tokenizer \
        php8.1-xml \
        php8.1-yaml \
        php8.1-zip \
    && mkdir -p /run/php \
    && chown -Rf www-data:www-data /var/lib/php

# Install Composer
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --quiet --install-dir=/usr/bin/ --filename=composer

# Install Node.js v14
RUN curl --silent --location https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update -y \
    && apt-get install -y nodejs

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -y \
    && apt-get install yarn

# Install MySQL (used on frontend for faster seeding...)
RUN apt-get update -y \
    && apt-get install -y mysql-client

# Install Google Cloud SDK
RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update -y \
    && apt-get install -y google-cloud-sdk \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud config set metrics/environment github_docker_image

# Install Dockerize
RUN wget https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && rm dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz

# Install Lokalise CLI v2
RUN curl -sfL https://raw.githubusercontent.com/lokalise/lokalise-cli-2-go/master/install.sh | sh

# Cleanup
RUN apt-get purge -y \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure PHP (fpm & cli)
COPY ./configs/php/fpm/php.ini ${PHP_DIR}/fpm/conf.d/custom.ini
COPY ./configs/php/fpm/php-fpm.conf ${PHP_DIR}/fpm/php-fpm.conf
COPY ./configs/php/fpm/pool.d/www.conf ${PHP_DIR}/fpm/pool.d/www.conf
COPY ./configs/php/cli/php.ini ${PHP_DIR}/cli/conf.d/custom.ini
