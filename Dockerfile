FROM hyperknot/baseimage16:1.0.1

MAINTAINER friends@niiknow.org

ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive

# start
RUN \
    cd /tmp \
# add nginx repo
    && curl -s https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \

# update repo, install nginx and module to get dependencies
    && apt-get update -y && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
       nano nginx \
       nginx-module-geoip \
       nginx-module-image-filter \
       gettext-base \
    && dpkg --configure -a \

# re-enable all default services
    && rm -f /etc/service/syslog-forwarder/down \
    && rm -f /etc/service/cron/down \
    && rm -f /etc/service/syslog-ng/down \
    && rm -f /core \

# geoip stuff
    && cd /tmp \
    && curl http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gzip -d - > /etc/nginx/GeoIP.dat \
    && curl http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gzip -d - > /etc/nginx/GeoLiteCity.dat \

# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# cleanup
    && apt-get clean -y && apt-get autoclean -y \
    && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/* \

# remove existing image filter module so we can overwrite with ours
    && rm -rf /etc/nginx/modules/ngx_http_image_filter_m*.so

ADD ./files /

EXPOSE 80

CMD ["/sbin/my_init"]
