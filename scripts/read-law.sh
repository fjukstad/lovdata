#!/usr/bin/env bash
# Read a Norwegian law and extract readable text.
#
# Usage:
#   ./read-law.sh <filename>                   Full law as plain text
#   ./read-law.sh <filename> --section <name>  Specific section (e.g. "kap30", "§371")
#   ./read-law.sh <filename> --header          Just the header/metadata
#
# The filename can be:
#   - Full filename: nl-20050520-028.xml
#   - Just the date-number part: 20050520-028
#   - A refID: lov/2005-05-20-28
#
# Output is the law text with HTML tags stripped, formatted for readability.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
NL_DIR="$DATA_DIR/nl"
INDEX_FILE="$SKILL_DIR/references/index.tsv"

SECTION=""
HEADER_ONLY=0
INPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --section) SECTION="$2"; shift 2 ;;
        --header) HEADER_ONLY=1; shift ;;
        *) INPUT="$1"; shift ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    echo "Usage: read-law.sh <filename|refID> [--section <name>] [--header]" >&2
    exit 1
fi

# Resolve input to a file path
resolve_file() {
    local input="$1"

    # If it looks like a refID (contains /), convert to filename pattern
    if [[ "$input" == *"/"* ]]; then
        local ref="${input##*/}"  # Get part after last /
        # ref is like 2005-05-20-28 or 1814-05-17 (no seq number)
        local date_part=$(echo "$ref" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2}).*/\1\2\3/')
        local seq_part=$(echo "$ref" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-?//')
        if [[ -z "$seq_part" ]]; then
            seq_part="000"
        else
            seq_part=$(printf "%03d" "$seq_part" 2>/dev/null || echo "$seq_part")
        fi
        input="${date_part}-${seq_part}"
    fi

    # Strip .xml extension if present
    input="${input%.xml}"
    # Strip nl- prefix if present
    input="${input#nl-}"

    local filepath="$NL_DIR/nl-${input}.xml"
    if [[ -f "$filepath" ]]; then
        echo "$filepath"
        return 0
    fi

    # Try fuzzy match
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

if [[ $HEADER_ONLY -eq 1 ]]; then
    # Extract just the header/metadata section
    python3 -c "
import sys, re, html

with open('$FILEPATH', 'r') as f:
    content = f.read()

# Extract header
header_match = re.search(r'<header[^>]*>(.*?)</header>', content, re.DOTALL)
if not header_match:
    print('No header found.')
    sys.exit(0)

header = header_match.group(1)

# Extract dt/dd pairs
pairs = re.findall(r'<dt[^>]*>(.*?)</dt>\s*<dd[^>]*>(.*?)</dd>', header, re.DOTALL)
for dt, dd in pairs:
    label = re.sub(r'<[^>]+>', '', dt).strip()
    value = re.sub(r'<[^>]+>', '', dd).strip()
    value = html.unescape(value)
    if value:
        print(f'{label}: {value}')
"
    exit 0
fi

# Extract and format law text
python3 -c "
import sys, re, html

with open('$FILEPATH', 'r') as f:
    content = f.read()

section_filter = '$SECTION'

if section_filter:
    # Find the section by data-name attribute or paragraph name
    # Try data-name match first
    pattern = rf'data-name=\"{re.escape(section_filter)}\"[^>]*>(.*?)(?=<(?:section|article) [^>]*data-name=|</section>|</main>|</body>)'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        content = match.group(1)
    else:
        # Try matching section/article with the name in the text
        pattern = rf'(?:<section|<article)[^>]*>(?:(?!</section>|</article>).)*?{re.escape(section_filter)}.*?(?:</section>|</article>)'
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        if match:
            content = match.group(0)
        else:
            print(f'Section \"{section_filter}\" not found.', file=sys.stderr)
            sys.exit(1)

# Strip changesToParent articles (amendment notes) for cleaner output
content = re.sub(r'<article class=\"changesToParent\">.*?</article>', '', content)

# Convert some HTML structure to readable formatting
content = re.sub(r'<h2[^>]*>', '\n\n== ', content)
content = re.sub(r'</h2>', ' ==\n', content)
content = re.sub(r'<h3[^>]*>', '\n\n=== ', content)
content = re.sub(r'</h3>', ' ===\n', content)
content = re.sub(r'<h4[^>]*>', '\n\n==== ', content)
content = re.sub(r'</h4>', ' ====\n', content)
content = re.sub(r'<li[^>]*>', '\n  - ', content)
content = re.sub(r'<br\s*/?>', '\n', content)
content = re.sub(r'<article class=\"legalP\"[^>]*>', '\n', content)

# Remove all remaining HTML tags
content = re.sub(r'<[^>]+>', '', content)

# Unescape HTML entities
content = html.unescape(content)

# Clean up whitespace
content = re.sub(r'\n{3,}', '\n\n', content)
content = re.sub(r'[ \t]+', ' ', content)
lines = content.strip().split('\n')
lines = [l.strip() for l in lines]
print('\n'.join(lines))
"
