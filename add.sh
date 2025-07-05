#!/bin/bash

ROUTES_DIR="routes"

ask_input() {
    read -p "$1: " value
    echo "$value" | tr '[:lower:]' '[:upper:]'
}

CALLSIGN=$(ask_input "Enter Callsign (e.g., THA020)")
FLIGHT_NO=$(ask_input "Enter Flight Number (e.g., XJ621)")
ROUTE=$(ask_input "Enter Route (e.g., BKK-NRT)")
LAST_UPDATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

IFS='-' read -ra AIRPORTS <<<"$ROUTE"

LEGS_JSON=$(jq -n '[]')

for ((i = 0; i < ${#AIRPORTS[@]} - 1; i++)); do
    DEP="${AIRPORTS[$i]}"
    ARR="${AIRPORTS[$i + 1]}"
    LEGS_JSON=$(jq --arg dep "$DEP" --arg arr "$ARR" '. + [{"dep_iata": $dep, "arr_iata": $arr}]' <<<"$LEGS_JSON")
done

FIRST_CHAR=$(echo "$CALLSIGN" | cut -c1 | tr '[:upper:]' '[:lower:]')
FILE_PATH="${ROUTES_DIR}/${FIRST_CHAR}.json"

if [ ! -f "$FILE_PATH" ]; then
    echo "[]" >"$FILE_PATH"
fi

EXISTING_ENTRY=$(jq --arg callsign "$CALLSIGN" '.[] | select(.callsign == $callsign)' "$FILE_PATH")

if [[ -n "$EXISTING_ENTRY" ]]; then
    echo "Existing entry found for callsign: $CALLSIGN"
    echo "$EXISTING_ENTRY" | jq .

    read -p "Do you want to update this entry? (y/n): " CONFIRM
    if [[ "${CONFIRM,,}" != "y" ]]; then
        echo "No changes made."
        exit 0
    fi

    jq --arg callsign "$CALLSIGN" 'del(.[] | select(.callsign == $callsign))' "$FILE_PATH" >temp.json && mv temp.json "$FILE_PATH"
fi

NEW_ENTRY=$(jq -n --arg callsign "$CALLSIGN" \
    --arg flight_no "$FLIGHT_NO" \
    --arg route "$ROUTE" \
    --arg last_updated "$LAST_UPDATED" \
    --argjson legs "$LEGS_JSON" \
    '{
       "callsign": $callsign,
       "flight_no": $flight_no,
       "route_iata_full": $route,
       "last_updated": $last_updated,
       "legs": $legs
   }')

jq --argjson newEntry "$NEW_ENTRY" '. += [$newEntry]' "$FILE_PATH" >temp.json && mv temp.json "$FILE_PATH"

echo -e "$CALLSIGN added/updated in $FILE_PATH:"
echo "$NEW_ENTRY" | jq .
