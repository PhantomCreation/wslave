FROM ubuntu:22.04

RUN apt-get update && apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
# NOTE: When the PHP FPM version changes, you MUST update the
#  version named in base/docker/nginx/supervisord.conf and
#  in base/docker/nginx/nginx.vhost, then rebuild the nweb image!
RUN apt-get install -y nginx php-fpm php-mysql \
	php-mbstring php-curl php-dom \
	php-imagick php-xml php-zip \
	composer nodejs npm \
	libpng-dev libjpeg-dev \
	mariadb-client mariadb-common \
	supervisor curl less
RUN apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db

COPY nginx.vhost /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.1/fpm/php.ini

RUN npm install yarn -g

RUN curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp
RUN wp --allow-root

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
