# Beebcast

Beebcast is a self-hosted [BBC podcast](https://www.bbc.co.uk/sounds/podcasts) manager. The application will download media files using [get_iplayer](https://get-iplayer.github.io/get_iplayer/), store them on your own server and generate HTML pages and RSS feeds for them. It can manage any audio file that get_iplayer can download, even if no official RSS feed is available.

It uses [exiftool](https://www.exiftool.org/) to extract metadata from the downloaded media and use them to populate the HTML pages and RSS feeds. All content is served as static files by the web server (Apache). It does not use a database or serve dynamic content.

## Build

An arm64 image is available from [Docker Hub](https://hub.docker.com/r/austozi/beebcast). It is based on the [TheSpad/docker-get_iplayer](https://github.com/TheSpad/docker-get_iplayer) image, with exiftool, apache2 and the run.sh script added on top.

If you wish to build your own image, simply clone this repo and execute `docker build .` from the directory where Dockerfile is.

## Install

The easiest way to install this application is using [docker-compose](https://docs.docker.com/compose/).

Example docker-compose.yml:

```
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
### Environment variables

| Variable      | Function |
|---------------------------|----------|
| BEEBCAST_BASEURL          | Public URL for the instance, defaults to http://localhost |
| BEEBCAST_FEED_ID          | Space-separated list of programme IDs, e.g. for the programme available at https://www.bbc.co.uk/programmes/b006s5dp, the programme ID is 'b006s5dp'. |
| BEEBCAST_MEDIA_PATH       | Folder inside docker container where the media files are to be mounted. Must be within the document root fo the Apache web server at /var/www/localhost/host |
| BEEBCAST_RETENTION_DAYS   | Number of days to retain downloaded media for. Media older than this will be automatically deleted. |
| BEEBCAST_REFRESH_INTERVAL | Number of seconds to wait upon a content update before starting the next one. |


