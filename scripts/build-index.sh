#!/usr/bin/env bash
# Build a searchable index of all Norwegian laws from the Lovdata public data.
# Downloads the latest gjeldende-lover.tar.bz2 if not already present or if
# older than 7 days, extracts it, and builds a TSV index file.
#
# Output: DATA_DIR/index.tsv with columns:
#   filename \t refID \t dokID \t shortTitle \t title
#
# Usage: ./build-index.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
ARCHIVE="$DATA_DIR/gjeldende-lover.tar.bz2"
NL_DIR="$DATA_DIR/nl"
REFERENCES_DIR="$SKILL_DIR/references"
INDEX_FILE="$REFERENCES_DIR/index.tsv"
URL="https://api.lovdata.no/v1/publicData/get/gjeldende-lover.tar.bz2"

mkdir -p "$DATA_DIR"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
fi

# Download if missing or older than 7 days
NEED_DOWNLOAD=0
if [[ ! -f "$ARCHIVE" ]]; then
    NEED_DOWNLOAD=1
elif [[ $FORCE -eq 1 ]]; then
    NEED_DOWNLOAD=1
elif [[ $(find "$ARCHIVE" -mtime +7 2>/dev/null | wc -l) -gt 0 ]]; then
    NEED_DOWNLOAD=1
fi

if [[ $NEED_DOWNLOAD -eq 1 ]]; then
    echo "Downloading gjeldende-lover.tar.bz2 ..."
    curl -sL -o "$ARCHIVE" "$URL"
    echo "Download complete ($(du -h "$ARCHIVE" | cut -f1))."
    # Remove old extracted data
    rm -rf "$NL_DIR"
fi

# Extract if needed
if [[ ! -d "$NL_DIR" ]]; then
    echo "Extracting ..."
    cd "$DATA_DIR"
    tar xjf gjeldende-lover.tar.bz2
    echo "Extracted $(ls "$NL_DIR" | wc -l | tr -d ' ') law files."
fi

# Build index
mkdir -p "$REFERENCES_DIR"
echo "Building index ..."
echo -e "filename\trefID\tdokID\tshortTitle\ttitle" > "$INDEX_FILE"

for f in "$NL_DIR"/*.xml; do
    basename="$(basename "$f")"
    # Extract title from <title> tag
    title=$(sed -n 's/.*<title>\([^<]*\)<\/title>.*/\1/p' "$f" | head -1)
    # Extract dokID
    dokid=$(sed -n 's/.*<dd class="dokid">\([^<]*\)<\/dd>.*/\1/p' "$f" | head -1)
    # Extract refID
    refid=$(sed -n 's/.*<dd class="refid">\([^<]*\)<\/dd>.*/\1/p' "$f" | head -1)
    # Extract short title
    short=$(sed -n 's/.*<dd class="titleShort">\([^<]*\)<\/dd>.*/\1/p' "$f" | head -1)
    echo -e "${basename}\t${refid}\t${dokid}\t${short}\t${title}" >> "$INDEX_FILE"
done

echo "Index built: $INDEX_FILE ($(wc -l < "$INDEX_FILE" | tr -d ' ') entries)"
