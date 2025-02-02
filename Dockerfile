# Multi-stage Dockerfile example

# Stage 1: Builder stage to install dependencies
FROM php:8.2-fpm AS builder

# Install system dependencies (git, zip, unzip, node, npm, etc.)
RUN apt-get update && apt-get install -y \
    git \
    zip \
    unzip \
    curl \
    libzip-dev \
    nodejs \
    npm \
    libexif-dev \
    libgd-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install zip exif gd intl pdo pdo_mysql

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# (Optional) Install PHPUnit globally or with Composer
# RUN composer global require phpunit/phpunit

WORKDIR /var/www/html

# Copy code from host to container
COPY ./code/ /var/www/html/

# Install PHP and JS dependencies
RUN composer install --optimize-autoloader
RUN npm install
# RUN npm run build  # (Optional) If you need a build step for your front-end

# Stage 2: final runtime image
FROM php:8.2-fpm

WORKDIR /var/www/html

# Copy from builder
COPY --from=builder /var/www/html /var/www/html

ENV FPM_PORT=${FPM_PORT:-9000}
EXPOSE $FPM_PORT
CMD ["php-fpm"]
