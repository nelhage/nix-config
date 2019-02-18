FROM docker
ADD https://github.com/nelhage/asciisnowmanforyou.com/archive/master.tar.gz /
RUN rm -rf /usr/share/nginx/html
RUN ln -nsf /asciisnowmanforyou.com-master/ /usr/share/nginx/html
