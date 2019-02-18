FROM nginx
ADD https://github.com/nelhage/asciisnowmanforyou.com/archive/master.tar.gz /tmp
RUN tar -C /usr/share/nginx/html --strip-components=1 /tmp/master.tar.gz
RUN rm /tmp/master.tar.gz
