FROM php:7.4-cli

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY ./php/custom.ini /usr/local/etc/php/conf.d/php-custom.ini

### Install components ###
RUN apt-get update -y && apt-get install -y \
  git \
  unzip \
  zip \
  # This package includes mbstring
  libonig-dev \
  # Add Intl extenxions
  libicu-dev \
  --no-install-recommends && \
  apt-get autoremove -y && \
  rm -r /var/lib/apt/lists/*

### Install OPcache ###
RUN docker-php-ext-install opcache

### Install xDebug ###

# If you're behind a corporate proxy uncomment the line below
# RUN pear config-set http_proxy http://proxy.company:000

RUN pecl channel-update pecl.php.net
RUN pecl install xdebug-2.8.1 \
    && docker-php-ext-enable xdebug

### Install Intl ###
RUN docker-php-ext-configure intl \
  && docker-php-ext-install intl

### Install MySQL ###
RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql

### Install Composer ###
RUN set -eux; \
  curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer; \
  php -r " \
    \$signature = '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
      unlink('/tmp/installer.php'); \
      echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
      exit(1); \
    }"; \
  php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer; \
  composer --ansi --version --no-interaction; \
  rm -f /tmp/installer.php; \
  find /tmp -type d -exec chmod -v 1777 {} +

### Install Laravel Installer ###
RUN composer global require laravel/installer \
&& echo 'export PATH=/root/.composer/vendor/bin:$PATH' >> ~/.bashrc


EXPOSE 80 443 9005 9000