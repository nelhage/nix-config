FROM nginx:mainline
RUN apt-get update && apt-get -y dist-upgrade
ADD dhparam.pem /etc/dhparam.pem
ADD nginx.conf /etc/nginx/nginx.conf
ADD 30-monitor-certs.sh /docker-entrypoint.d
