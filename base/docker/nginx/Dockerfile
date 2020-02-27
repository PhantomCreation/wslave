FROM ubuntu:18.04

RUN apt-get update \
&& apt-get install -y libpng-dev libjpeg-dev mariadb-client mariadb-common \
&& apt-get clean
RUN adduser www-data root
RUN mkdir /db \
&& chmod 777 /db
