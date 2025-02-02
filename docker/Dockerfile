# Stage 0: base
FROM php:8.2-fpm as base

# minimal packages for runtime
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libexif-dev \
    libgd-dev \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install zip exif gd intl pdo pdo_mysql \
    && echo "display_errors=On" > /usr/local/etc/php/conf.d/error-logging.ini \
    && echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/error-logging.ini \
    && echo "log_errors=On" >> /usr/local/etc/php/conf.d/error-logging.ini \
    && echo "error_log=/proc/self/fd/2" >> /usr/local/etc/php/conf.d/error-logging.ini \
    && echo "catch_workers_output = yes" >> /usr/local/etc/php-fpm.d/zz-catch-output.conf

# Stage 1: builder
FROM base AS builder

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    nodejs \
    npm \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# Stage 2: app
FROM base as app

WORKDIR /var/www/html

ENV FPM_PORT=${FPM_PORT:-9000}
EXPOSE $FPM_PORT

CMD ["php-fpm"]
