FROM php:8.3.7-apache

RUN a2enmod rewrite
RUN service apache2 restart
RUN apt-get update \
&& apt-get install -y libpng-dev libjpeg-dev mariadb-client mariadb-common libonig-dev \
&& docker-php-ext-install gd \
&& docker-php-ext-install mbstring \
&& docker-php-ext-install mysqli \
&& docker-php-ext-install pdo \
&& docker-php-ext-install pdo_mysql \
&& docker-php-ext-install opcache \
&& apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db
