version: "3"
services:
  beebcast:
    image: docker.io/austozi/beebcast:latest
    container_name: beebcast
    restart: unless-stopped
    environment:
      PUID: 1000
      GUID: 1000
      TZ: Europe/London
      BEEBCAST_BASEURL: https://beebcast.example.com
      BEEBCAST_FEED_ID: "b006r9yq b006qgt7 b00vhfnv b007mf4f b006s5dp"
      # b006r9yq: News Quiz
      # b006qgt7: The Now Show
      # b00vhfnv: Great Unanswered Questions
      # b007mf4f: The Unbelievable Truth
      # b006s5dp: Just a Minute
      BEEBCAST_MEDIA_PATH: /var/www/localhost/htdocs/media
      BEEBCAST_RETENTION_DAYS: 180
      BEEBCAST_REFRESH_INTERVAL: 3600
    volumes:
      - ./config:/config
      - ./config/www:/var/www/localhost/htdocs
      - /media/elements/podcasts:/var/www/localhost/htdocs/media
    expose:
      - 80
    networks:
      - proxy
networks:
  proxy:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.33.0/29
