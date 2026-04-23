FROM php:8.2-apache

LABEL maintainer="John Jonah <johnjonah0866@gmail.com>"
LABEL version="1.0.0"
LABEL description="DevOps Demo PHP Application"


ENV APP_ENV="production" \
    APP_VERSION="1.0.0" \
    DB_HOST="mysql" \
    DB_NAME="devops_db" \
    DB_USER="devops_user" \
    DB_PASS="devops_pass"



    RUN apt-get update && apt-get install -y\
        libpq-dev \
        curl \
        && docker-php-ext-install pdo pdo_mysql \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*


WORKDIR /var/www/html

COPY src/ .


RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1


CMD ["apache2-foreground"]    

