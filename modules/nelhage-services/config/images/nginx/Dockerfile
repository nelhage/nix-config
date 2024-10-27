FROM nginx:1.25.4
RUN apt-get update && apt-get -y install procps && apt-get -y dist-upgrade && apt-get clean
ADD dhparam.pem /etc/dhparam.pem
ADD nginx.conf /etc/nginx/nginx.conf
ADD 30-monitor-certs.sh /docker-entrypoint.d
