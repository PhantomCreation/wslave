FROM ubuntu:20.04

COPY nginx.vhost /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install -y nginx php-fpm php-mysql \
	libpng-dev libjpeg-dev \
	mariadb-client mariadb-common \
	supervisor curl
RUN apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db

RUN mkdir /run/php

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
