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
    && docker-php-ext-install zip exif gd intl pdo pdo_mysql

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

WORKDIR /var/www/html
COPY ./code/ /var/www/html/
RUN composer install --optimize-autoloader
RUN npm install

# Stage 2: app
FROM base as app

WORKDIR /var/www/html
COPY --from=builder /var/www/html /var/www/html

ENV FPM_PORT=${FPM_PORT:-9000}
EXPOSE $FPM_PORT

CMD ["php-fpm"]
