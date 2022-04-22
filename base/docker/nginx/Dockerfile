FROM ubuntu:22.04

RUN apt-get update && apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
# NOTE: When the PHP FPM version changes, you MUST update the 
#  version named in base/docker/nginx/supervisord.conf and
#  in base/docker/nginx/nginx.vhost, then rebuild the nweb image!
RUN apt-get install -y nginx php8.1-fpm php-mysql \
	php8.1-mbstring php8.1-curl php8.1-dom \
	php8.1-imagick php8.1-xml php8.1-zip \
	libpng-dev libjpeg-dev \
	mariadb-client mariadb-common \
	supervisor curl
RUN apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db

COPY nginx.vhost /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.1/fpm/php.ini

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
