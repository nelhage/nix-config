FROM goacme/lego
ADD manage-certs /
RUN apk add bash
RUN addgroup -g 101 -S nginx && adduser --uid 101 -S nginx -G nginx
USER nginx:nginx
ENTRYPOINT ["/manage-certs"]
