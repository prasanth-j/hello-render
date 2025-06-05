########################
# 1. BUILD STAGE
########################
FROM composer:2.7 AS build

WORKDIR /app

# Copy only composer files first (for caching)
COPY composer.json composer.lock ./

# Install optimized vendor packages (no dev)
RUN composer install --no-dev --optimize-autoloader

# Now copy full Laravel app
COPY . .

########################
# 2. RUNTIME STAGE
########################
FROM php:8.3-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    bash \
    curl \
    libpng \
    libjpeg-turbo-dev \
    libzip-dev \
    unzip \
    oniguruma-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    zlib-dev \
    git \
    mariadb-connector-c-dev \
    tzdata

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl

# Copy project files from build stage
COPY --from=build /app /var/www/html

# Copy default .env if none present
RUN cp .env.example .env

# Fix permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R ug+rwx storage bootstrap/cache

# Copy Nginx config
COPY conf/nginx/app.conf /etc/nginx/http.d/default.conf

# Expose web port
EXPOSE 80

# Start services: generate APP_KEY if missing, cache configs, run php-fpm and nginx
CMD ["/bin/sh", "-c", "\
    if ! grep -q 'APP_KEY=base64:' .env; then \
        echo '>>> Generating APP_KEY'; \
        php artisan key:generate --force; \
    fi && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php-fpm -D && \
    nginx -g 'daemon off;'"]
