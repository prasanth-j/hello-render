# ---------- Build stage ----------
FROM composer:2.7 AS build
WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader \
 && php artisan key:generate --ansi \
 && php artisan config:cache route:cache view:cache

# ---------- Runtime stage ----------
FROM nginx:alpine
# copy app + nginx conf
COPY --from=build /app /var/www/html
COPY conf/nginx/app.conf /etc/nginx/conf.d/default.conf
WORKDIR /var/www/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
