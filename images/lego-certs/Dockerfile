FROM goacme/lego:v4.15
ADD manage-certs /
RUN apk add bash
RUN addgroup -g 101 -S nginx && adduser --uid 101 -S nginx -G nginx
RUN mkdir /opt/lego
RUN chown nginx:nginx /opt/lego
USER nginx:nginx
ENTRYPOINT ["/manage-certs"]
