FROM node:12-bullseye AS node
FROM php:7.4-apache-bullseye

# Configure NPM
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Copy our local apache configuration to the container
COPY ./docker/apache2/vhost.conf /etc/apache2/sites-available/shop-guidance.conf
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini

# Update packages and install new ones
RUN apt-get update
RUN apt-get install -y curl \
    vim \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    zip unzip \
    libxml2-dev \
    libpng-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libpng-dev  \
    libxpm-dev \
    libfreetype6-dev \
    libonig-dev \
    python2 \
    g++ \
    make

# Deal ith Apache configuration
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf &&\
    a2enmod rewrite &&\
    a2dissite 000-default &&\
    a2ensite shop-guidance

# PHP extensions
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ \
                                --with-freetype=/usr/include/
RUN docker-php-ext-configure opcache --enable-opcache
RUN docker-php-ext-install pdo pdo_mysql mysqli zip dom gd intl json mbstring xml soap opcache

# Sendmail
RUN curl -sSL https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 -o mhsendmail \
    && chmod +x mhsendmail \
    && mv mhsendmail /usr/local/bin/mhsendmail
RUN echo "sendmail_path=\"/usr/local/bin/mhsendmail --smtp-addr=guidance_mailhog:1025\"" >> /usr/local/etc/php/conf.d/sendmail.ini &&\
   echo "sendmail_from=\"nobodybro@4zev7ezv7.dev\"" >> /usr/local/etc/php/conf.d/sendmail.ini &&\
    rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

RUN usermod -u 1000 www-data