ARG livegrep_image_version

FROM ghcr.io/livegrep/livegrep/indexer:${livegrep_image_version}
ADD rebuild-index /usr/local/bin/
CMD /usr/local/bin/rebuild-index
