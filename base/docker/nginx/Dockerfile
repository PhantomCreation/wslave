FROM ubuntu:18.04

RUN apt-get update \
&& apt-get install -y nginx libpng-dev libjpeg-dev mariadb-client mariadb-common \
&& apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
