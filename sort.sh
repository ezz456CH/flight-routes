#!/bin/bash

ROUTES_DIR="routes"

for FILE in "$ROUTES_DIR"/*.json; do
    jq --indent 4 'sort_by(.callsign | capture("(?<letters>\\D+)(?<numbers>\\d+)") | .letters, (.numbers | tonumber))' "$FILE" >"$FILE.tmp"

    mv "$FILE.tmp" "$FILE"

    echo "Processed and overwritten $FILE"
done

echo "All files in $ROUTES_DIR have been sorted."
