#!/usr/bin/env bash
# Search the law index and optionally the full text of laws.
#
# Usage:
#   ./search-laws.sh <query>                  Search index (titles)
#   ./search-laws.sh --fulltext <query>       Full-text search across all laws
#   ./search-laws.sh --fulltext --max 5 <q>   Limit full-text results
#
# Index search returns matching lines from index.tsv.
# Full-text search uses ripgrep across all XML files and returns
# the paragraph context for each match.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
NL_DIR="$DATA_DIR/nl"
INDEX_FILE="$SKILL_DIR/references/index.tsv"

if [[ ! -f "$INDEX_FILE" ]]; then
    echo "Index not found. Run build-index.sh first." >&2
    exit 1
fi

FULLTEXT=0
MAX=20
QUERY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fulltext) FULLTEXT=1; shift ;;
        --max) MAX="$2"; shift 2 ;;
        *) QUERY="$1"; shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "Usage: search-laws.sh [--fulltext] [--max N] <query>" >&2
    exit 1
fi

if [[ $FULLTEXT -eq 0 ]]; then
    # Search the index (titles and short titles)
    echo "=== Index search for: $QUERY ==="
    rg -i "$QUERY" "$INDEX_FILE" | head -"$MAX" || echo "No matches found."
else
    # Full-text search across all law XML files
    echo "=== Full-text search for: $QUERY (max $MAX results) ==="
    matches=$(rg -il "$QUERY" "$NL_DIR"/*.xml 2>/dev/null | head -"$MAX")
    if [[ -z "$matches" ]]; then
        echo "No matches found."
        exit 0
    fi
    echo "$matches" | while read -r filepath; do
        basename="$(basename "$filepath")"
        # Get the law title from the index
        title=$(rg "^${basename}" "$INDEX_FILE" 2>/dev/null | cut -f5)
        echo ""
        echo "--- $basename: $title ---"
        # Show matching paragraph context. Extract readable text around matches.
        # Use rg to find matches with byte offset context, limit output.
        rg -o ".{0,80}${QUERY}.{0,80}" "$filepath" -i 2>/dev/null | head -3
    done
fi
