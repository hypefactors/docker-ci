# to get docker, on which circleci is dependent
FROM docker:17.12.0-ce as static-docker-source

FROM ubuntu:22.04

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
        ghostscript \
        gnupg \
        unzip \
        wget \
        software-properties-common \
        vim \
        # Cypress related
        libatk-bridge2.0-0 \
        libgtk-3.0 \ 
        libgtk2.0-0 \
        libnotify-dev \
        libgconf-2-4 \
        libnss3 \
        libxss1 \
        libasound2 \
        libgbm1 \
        xvfb \
        snapd

# Setup GnuPG
RUN echo "Setting up: GnuPG" \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && echo "keyserver hkp://keyserver.ubuntu.com:80" >> ~/.gnupg/dirmngr.conf \
    && gpg --homedir ~/.gnupg --recv-keys E5267A6C \
    && gpg --homedir ~/.gnupg --recv-keys C300EE8C    

# Install and setup PHP
RUN echo "Setting up: PHP" \
    && gpg --recv-key 0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c \
    && gpg --export 0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c > /usr/share/keyrings/ppa_ondrej_php.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu  jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt update \
    && apt install -y --only-upgrade libpcre2-8-0 \
    && apt install -y --no-install-recommends \
        php8.4-cli \
        php8.4-fpm \
        php8.4-apcu \
        php8.4-bcmath \
        php8.4-bz2 \
        php8.4-ctype \
        php8.4-curl \
        php8.4-fileinfo \
        php8.4-gd \
        php8.4-gmp \
        php8.4-igbinary \
        php8.4-imap \
        php8.4-intl \
        php8.4-mbstring \
        php8.4-msgpack \
        php8.4-mysql \
        php8.4-readline \
        php8.4-redis \
        php8.4-tokenizer \
        php8.4-xml \
        php8.4-zip \
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
