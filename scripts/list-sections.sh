#!/usr/bin/env bash
# List all sections/chapters/paragraphs in a law file.
#
# Usage:
#   ./list-sections.sh <filename|refID>
#
# Output: Indented table of contents showing the structure of the law.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
NL_DIR="$DATA_DIR/nl"

INPUT="${1:-}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: list-sections.sh <filename|refID>" >&2
    exit 1
fi

# Resolve input to a file path (same logic as read-law.sh)
resolve_file() {
    local input="$1"
    if [[ "$input" == *"/"* ]]; then
        local ref="${input##*/}"
        local date_part=$(echo "$ref" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2}).*/\1\2\3/')
        local seq_part=$(echo "$ref" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-?//')
        if [[ -z "$seq_part" ]]; then
            seq_part="000"
        else
            seq_part=$(printf "%03d" "$seq_part" 2>/dev/null || echo "$seq_part")
        fi
        input="${date_part}-${seq_part}"
    fi
    input="${input%.xml}"
    input="${input#nl-}"
    local filepath="$NL_DIR/nl-${input}.xml"
    if [[ -f "$filepath" ]]; then
        echo "$filepath"
        return 0
    fi
    local matches
    matches=$(ls "$NL_DIR"/nl-*"${input}"*.xml 2>/dev/null | head -5)
    if [[ -n "$matches" ]]; then
        echo "$matches" | head -1
        return 0
    fi
    echo "File not found for: $input" >&2
    return 1
}

FILEPATH=$(resolve_file "$INPUT")

python3 -c "
import re, html

with open('$FILEPATH', 'r') as f:
    content = f.read()

# Extract title
title_match = re.search(r'<title>([^<]+)</title>', content)
if title_match:
    print(title_match.group(1))
    print('=' * len(title_match.group(1)))
    print()

# Extract TOC from the document if present
toc_match = re.search(r'<dd class=\"table-of-contents\">(.*?)</dd>', content, re.DOTALL)
if toc_match:
    toc = toc_match.group(1)
    # Parse list items with nesting level
    items = re.findall(r'<a[^>]*>([^<]+)</a>', toc)
    # Re-parse with depth tracking
    depth = 0
    for tag in re.finditer(r'(<ul[^>]*>|</ul>|<a[^>]*>([^<]+)</a>)', toc):
        full = tag.group(0)
        if full.startswith('<ul'):
            depth += 1
        elif full.startswith('</ul'):
            depth -= 1
        elif tag.group(2):
            text = html.unescape(tag.group(2).strip())
            indent = '  ' * (depth - 1)
            print(f'{indent}{text}')
else:
    # Fall back to extracting headings from the document body
    headings = re.findall(r'<(h[234])[^>]*>(.*?)</\1>', content)
    for tag, text in headings:
        text = re.sub(r'<[^>]+>', '', text).strip()
        text = html.unescape(text)
        level = int(tag[1]) - 2
        indent = '  ' * level
        print(f'{indent}{text}')
"
