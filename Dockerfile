FROM debian:latest
MAINTAINER tomh@uwm.edu
RUN apt-get update
RUN apt-get install -y perl cron libwww-perl imagemagick

# copy the script and crontab entry file
COPY . /root

# configure container for local time zone
RUN ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime
RUN echo America/Chicago > /etc/timezone


RUN crontab < /root/crontab



CMD [ "cron" , "-f" ]
