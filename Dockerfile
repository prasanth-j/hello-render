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
    libjpeg \
    git \
    supervisor

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy existing application
COPY . .

# Copy .env file from example
RUN cp .env.example .env

# Fix permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R ug+rwx storage bootstrap/cache

# Copy Nginx config
COPY conf/nginx/app.conf /etc/nginx/http.d/default.conf

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Expose port 80
EXPOSE 80

# Start PHP-FPM and Nginx using supervisor
CMD ["/bin/sh", "-c", "php artisan config:cache && php-fpm -D && nginx -g 'daemon off;'"]
