# Multi-stage Dockerfile example

# Stage 1: Builder stage to install dependencies
FROM php:8.1-fpm AS builder

# Install system dependencies (git, zip, unzip, node, npm, etc.)
RUN apt-get update && apt-get install -y \
    git \
    zip \
    unzip \
    curl \
    libzip-dev \
    nodejs \
    npm \
    && docker-php-ext-install zip

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
FROM php:8.1-fpm

WORKDIR /var/www/html

# Copy from builder
COPY --from=builder /var/www/html /var/www/html

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
