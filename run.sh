#!/bin/bash -e

# User-defined environment variables with defaults:
if [ "$BEEBSCAST_BASEURL" == "" ]; then
	BEEBSCAST_BASEURL="http://localhost"
fi

if [ "$BEEBSCAST_MEDIA_PATH" == "" ]; then
	BEEBSCAST_MEDIA_PATH="/var/www/localhost/htdocs/media"
fi

if [ "$BEEBSCAST_FEED_ID" == "" ]; then
	BEEBSCAST_FEED_ID="b006s5dp"
else
	echo "Programme IDs (space-separated): $BEEBSCAST_FEED_ID"
fi

if [ "$BEEBSCAST_RETENTION_DAYS" == "" ]; then
	BEEBSCAST_RETENTION_DAYS=180
fi

if [ "$BEEBSCAST_REFRESH_INTERVAL" == "" ]; then
	BEEBSCAST_REFRESH_INTERVAL=3600
fi

# Hardcoded environment variables:
BEEBSCAST_WEBROOT="/var/www/localhost/htdocs"

# Reusable function to generate RSS feed:
generate_feed() {
	# Gather information about the programme:
	local programmeId="$1"
	local programmeUrl="https://www.bbc.co.uk/programmes/$programmeId"
	local scrapedHtml=$(curl -sL "$programmeUrl")
	local albumArtUrl=$(echo "$scrapedHtml" | grep -Eom 1 "<link rel=\"apple-touch-icon\" sizes=\"152x152\" href=\"[^\"]+\">" | cut -d '"' -f 6)
	local albumTitle=$(echo "$scrapedHtml" | grep -Eom 1 "<a href=\"/programmes\/[a-z0-9]+\">.+<\/a>" | cut -d ">" -f 2 | cut -d "<" -f 1)
	local albumDescription=$(echo "$scrapedHtml" | grep -Eom 1 "<meta name=\"description\" content=\"[^\"]+\">" | cut -d '"' -f 4)
	local albumPubDate=$(date +%c)

	# Create folder for rss and media files:
	mkdir -p "$BEEBSCAST_MEDIA_PATH/$programmeId"

	# Download media files;
	# Note the path is path within the container, not the Docker host:
	get_iplayer --prefs-add --subtitles --output "$BEEBSCAST_MEDIA_PATH/$programmeId"
	get_iplayer --pid-recursive --pid "$programmeId"

	# Create XML file:
	local xmlContent="<?xml version=\"1.0\" encoding=\"UTF-8\"?><rss version=\"2.0\"><channel><title>$albumTitle</title><link>$programmeUrl</link><image><url>$albumArtUrl</url><title>$albumTitle</title><link>$programmeUrl</link></image><description>$albumDescription</description><pubDate>$albumPubDate</pubDate>"
    	local audioPath="$BEEBSCAST_MEDIA_PATH/$programmeId"

	# Create HTML file:
	local htmlContent="<!DOCTYPE HTML><html lang=\"en\">"
	htmlContent="$htmlContent<head>"
	htmlContent="$htmlContent<title>$albumTitle</title>"
	htmlContent="$htmlContent<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\"/>"
	htmlContent="$htmlContent</head>"
	htmlContent="$htmlContent<body>"
	htmlContent="$htmlContent<h1>$albumTitle</h1>"
	htmlContent="$htmlContent<p>$albumDescription</p>"
	htmlContent="$htmlContent<p><a href=\"/media/$programmeId/index.xml\">RSS feed</a></p>"
	htmlContent="$htmlContent<p><a href=\"$programmeUrl\"><img src=\"$albumArtUrl\" alt=\"$albumTitle\" width=\"160\" height=\"160\"/></a></p>"

	# Before looping through the audio files, delete outdated ones based on retention schedule:
	find "$audioPath" -mtime +$BEEBSCAST_RETENTION_DAYS -type f -delete
	for audioFile in $(ls -trU "$audioPath"/*.m4a); do
		# Gather information about media file:
		echo "Processing: $audioFile"
		audioTitle=$(exiftool -Title -E -s -s -s "$audioFile")
		audioDescription=$(exiftool -Lyrics -E -s -s -s "$audioFile" | sed -E "s@(PLAY|INFO): https://www.bbc.co.uk/programmes/[a-z0-9]+@@g" | sed -E "s|[\.]{2,}|\. |g" | sed -E "s|\. +\.|\.|g")
		audioPubDate=$(exiftool -ContentCreateDate -s -s -s -d %c "$audioFile")
		audioUrl=$BEEBSCAST_BASEURL/media/$programmeId/$(basename "$audioFile" .m4a).m4a

		# Update XML file with media information:
		xmlContent="$xmlContent<item><title>$audioTitle</title><description>$audioDescription</description><pubDate>$audioPubDate</pubDate><enclosure url=\"$audioUrl\" type=\"audio/mpeg\" medium=\"audio\"/></item>"

		# Update HTML file with media information:
		htmlContent="$htmlContent<h2>$audioTitle</h2><p>$audioPubDate</p><p>$audioDescription</p><p><a href=\"$audioUrl\">Download media file</a></p>"
	done

	# Wrap up XML file and save to file system:
	xmlContent="$xmlContent</channel></rss>"
	echo "$xmlContent" > "$BEEBSCAST_WEBROOT/media/$programmeId/index.xml"

	# Wrap up HTML file and save to file system:
	htmlContent="$htmlContent</body></html>"
	echo "$htmlContent" > "$BEEBSCAST_WEBROOT/media/$programmeId/index.html"
}

generateIndices() {
	local feed_id_list="$1"
	echo "--------------------------------"
	indexHtml="<!DOCTYPE HTML>"
	indexHtml="$indexHtml<html lang=\"en\"><head><title>Beebscast</title>"
	indexHtml="$indexHtml<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\"/>"
	indexHtml="$indexHtml</head>"
	indexHtml="$indexHtml<body>"
	indexHtml="$indexHtml<h1>Beebcasts</h1>"
	indexHtml="$indexHtml<p>Podcasts from the <a href=\"https://www.bbc.co.uk/sounds\">BBC</a></p>"
	indexHtml="$indexHtml<ul>"
	
	for feedId in $BEEBSCAST_FEED_ID; do
		local albumTitle=$(curl -sL "https://www.bbc.co.uk/programmes/$feedId" | grep -Eom 1 "<a href=\"/programmes/[a-z0-9]+\">.+</a>" | sed -E "s|<[^>]+>||g")
		generate_feed "$feedId"
		echo "--------------------------------"
		indexHtml="$indexHtml<li><a href=\"/media/$feedId/\">$albumTitle</a> (<a href=\"/media/$feedId/index.xml\">RSS</a>)</li>"
	done

	indexHtml="$indexHtml</ul></body></html>"
	echo "$indexHtml" > "$BEEBSCAST_WEBROOT/index.html"

	sleep $BEEBSCAST_REFRESH_INTERVAL
}

httpd -D FOREGROUND &
generateIndices
