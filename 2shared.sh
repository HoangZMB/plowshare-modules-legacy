#!/bin/bash
#
# 2shared module for plowshare.
#
MODULE_2SHARED_REGEXP_URL="http://\(www\.\)\?2shared.com/file/"
MODULE_2SHARED_DOWNLOAD_OPTIONS=
MODULE_2SHARED_UPLOAD_OPTIONS=

# Output a 2shared file download URL
#
# $1: A 2shared URL
#
2shared_download() {
    URL=$1   
    curl "$URL" | parse "window.location" "location = \"\(.*\)\";" || 
        { debug "file not found"; return 1; }
}

# Upload a file to 2shared
#
# $1: File path
#
2shared_upload() {
    FILE=$1
    UPLOADURL="http://www.2shared.com/"

    debug "downloading upload page: $UPLOADURL"
    DATA=$(curl "$UPLOADURL")
    ACTION=$(echo "$DATA" | parse "uploadForm" 'action="\([^"]*\)"') ||
        { debug "cannot get upload form URL"; return 1; }
    COMPLETE=$(echo "$DATA" | parse "uploadComplete" 'location="\([^"]*\)"')
    debug "starting file upload: $FILE"
    STATUS=$(curl -F "mainDC=1" \
        -F "fff=@$FILE;filename=$(basename "$FILE")" \
        "$ACTION")
    match "upload has successfully completed" "$STATUS" ||
        { debug "error on upload"; return 1; }
    DONE=$(curl "$UPLOADURL/$COMPLETE")
    URL=$(echo "$DONE" | parse 'name="downloadLink"' "\(http:[^<]*\)")
    ADMIN=$(echo "$DONE" | parse 'name="adminLink"' "\(http:[^<]*\)")
    echo "$URL ($ADMIN)"   
}