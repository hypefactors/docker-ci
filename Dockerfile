# to get docker, on which circleci is dependent
FROM docker:17.12.0-ce as static-docker-source

FROM ubuntu:20.04

LABEL maintainer="support@hypefactors.com"

# Avoid prompts while building
ENV DEBIAN_FRONTEND=noninteractive

ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# good colors for most applications
ENV TERM=xterm

# avoid million NPM install messages
ENV npm_config_loglevel=warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm=true

ENV CLOUD_SDK_VERSION=232.0.0

ENV DOCKERIZE_VERSION v0.6.1

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Install stuff
RUN apt-get update -y && apt-get upgrade -y \
    \
    # Install required dependencies
    && apt-get install -y \
        gnupg \
        ca-certificates \
        # apt-utils \
        apt-transport-https \
        curl \
        unzip \
        git \
        wget \
        libgtk2.0-0 \
        libnotify-dev \
        libgconf-2-4 \
        libnss3 \
        libxss1 \
        libasound2 \
        xvfb \
        snapd \
        # software-properties-common \
        lsb-release \
        libpq-dev \
        libpng-dev \
    # Setup GnuPG
    && mkdir -p ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    \
    # Install and setup PHP
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update -y \
    && apt-get install -y \
        php7.4-cli \
        php7.4-fpm \
        php7.4-apcu \
        php7.4-apcu-bc \
        php7.4-bcmath \
        php7.4-bz2 \
        php7.4-ctype \
        php7.4-curl \
        php7.4-fileinfo \
        php7.4-gd \
        php7.4-gmp \
        php7.4-igbinary \
        php7.4-imagick \
        php7.4-imap \
        php7.4-intl \
        php7.4-json \
        php7.4-mbstring \
        php7.4-msgpack \
        php7.4-mysql \
        php7.4-readline \
        php7.4-redis \
        php7.4-soap \
        php7.4-tokenizer \
        php7.4-xml \
        php7.4-yaml \
        php7.4-zip \
    && mkdir -p /run/php \
    && chown -Rf www-data:www-data /var/lib/php \
    \
    # Install Composer
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --quiet --install-dir=/usr/bin/ --filename=composer \
    \
    # Install Node.js v12
    && curl --silent --location https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get update -y \
    && apt-get install -y nodejs \
    \
    # Install Yarn
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -y \
    && apt-get install yarn \
    \
    # Install MySQL
    && apt-get update -y \
    && apt-get install -y mysql-client \
    \
    # Install Google Cloud SDK
    && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update -y \
    && apt-get install -y google-cloud-sdk \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud config set metrics/environment github_docker_image \
    \
    # Install Dockerize
    && wget https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && rm dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    \
    # && curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | bash \
    \
    # Cleanup
    && apt-get purge -y \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# CircleCI
COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
ADD https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci /usr/local/bin/circleci
RUN chmod +x /usr/local/bin/circleci
