FROM ubuntu:24.04

RUN apt-get update && apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get install -y nginx php-fpm php-mysql \
	php-mbstring php-curl php-dom \
	php-imagick php-xml php-zip \
	composer nodejs npm \
	libpng-dev libjpeg-dev \
	mariadb-client mariadb-common \
	supervisor curl less neovim emacs
RUN apt-get clean

RUN mkdir /db \
	&& chmod 777 /db

COPY nginx.vhost /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# NOTE: When the PHP FPM version changes, you MUST change the
#   version definition right below this comment, then you must
#   rebuild the nweb image!
ARG PHP_FPM_VERSION=8.3
RUN mkdir -p /run/php
COPY php.ini /etc/php/$PHP_FPM_VERSION/fpm/php.ini
RUN ln -s /usr/sbin/php-fpm$PHP_FPM_VERSION /usr/sbin/php-fpm
RUN ln -s /run/php/php$PHP_FPM_VERSION-fpm.sock /run/php/php-fpm.sock
RUN ln -s /run/php/php$PHP_FPM_VERSION-fpm.pid /run/php/php-fpm.pid

RUN npm install yarn -g

# The lines below install wp-cli in the container. However, since
#	wp-cli is run as root it causes various permission problems. In 
#	the future this may be re-added with some method of correcting 
#	permissions. Until then, please use wp-cli locally.
#RUN curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
#RUN chmod +x /usr/local/bin/wp
#RUN mkdir /root/.wp-cli
#COPY wp-cli.yml /root/.wp-cli/config.yml
#RUN echo 'alias wp="wp --allow-root"' >>  /root/.bashrc

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
