# Beebscast

A self-hosted BBC podcast manager. The application will download media files using [get_iplayer](https://get-iplayer.github.io/get_iplayer/), store them on your own server and generate HTML pages and RSS feeds for them. 

It uses [exiftool](https://www.exiftool.org/) to extract metadata from the downloaded media and use them to populate the HTML page and RSS feed. All content is served as static files by the web server (Apache). It does not use a database or serve dynamic content.

## Build

An arm64 image is available from [Docker Hub](https://hub.docker.com/r/austozi/beebscast). It is based on the [TheSpad/docker-get_iplayer image](https://github.com/TheSpad/docker-get_iplayer). 

If you wish to build your own image, simply clone this repo and execute `docker build .` from the directory where Dockerfile is.

## Install

The easiest way to install this application is using [docker-compose](https://docs.docker.com/compose/).

Example docker-compose.yml:

```
version: "3"
services:
  beebscast:
    image: docker.io/austozi/beebscast:latest
    container_name: beebscast
    restart: unless-stopped
    environment:
      PUID: 1000
      GUID: 1000
      TZ: Europe/London
      BEEBSCAST_BASEURL: https://beebscast.example.com
      BEEBSCAST_FEED_ID: "b006r9yq b006qgt7 b00vhfnv b007mf4f b006s5dp"
      # b006r9yq: News Quiz
      # b006qgt7: The Now Show
      # b00vhfnv: Great Unanswered Questions
      # b007mf4f: The Unbelievable Truth
      # b006s5dp: Just a Minute
      BEEBSCAST_MEDIA_PATH: /var/www/localhost/htdocs/media
      BEEBSCAST_RETENTION_DAYS: 180
      BEEBSCAST_REFRESH_INTERVAL: 3600
    volumes:
      - ./config:/config
      - ./config/www:/var/www/localhost/htdocs
      - ./podcasts:/var/www/localhost/htdocs/media
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
```
