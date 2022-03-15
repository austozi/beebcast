FROM ghcr.io/thespad/get_iplayer:latest
LABEL maintainer=austozi
RUN apk add --no-cache \
  apache2 \
  exiftool
ADD run.sh /run.sh
EXPOSE 80
CMD ["/bin/sh", "/run.sh"]
