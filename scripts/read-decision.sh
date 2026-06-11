#!/usr/bin/env bash
# Read a Norwegian court decision from rettspraksis.no.
#
# Usage:
#   ./read-decision.sh <case-id>                  Full decision text
#   ./read-decision.sh <case-id> --summary        Just metadata and summary
#   ./read-decision.sh <case-id> --section <N>     Paragraphs N through N+context
#
# Examples:
#   ./read-decision.sh "HR-2016-1440-A"
#   ./read-decision.sh "LA-1999-167" --summary
#   ./read-decision.sh "Rt-1997-550" --summary
#   ./read-decision.sh "LG-1993-502"
#
# Case IDs follow Norwegian conventions:
#   HR-YYYY-NNNN-A/S/U  = Hoyesterett (2008+)
#   Rt-YYYY-PAGE         = Hoyesterett (pre-2008, Rettstidende)
#   LA/LB/LE/LF/LG/LH-YYYY-NNNNN = Lagmannsrettene
#   RG-YYYY-PAGE         = Rettens Gang (lagmannsrett/tingrett collections)
#   T*-YYYY-NNNNN        = Tingrettene

set -euo pipefail

CASE_ID=""
SUMMARY_ONLY=0
SECTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --summary) SUMMARY_ONLY=1; shift ;;
        --section) SECTION="$2"; shift 2 ;;
        *) CASE_ID="$1"; shift ;;
    esac
done

if [[ -z "$CASE_ID" ]]; then
    echo "Usage: read-decision.sh <case-id> [--summary] [--section N]" >&2
    echo "" >&2
    echo "Read a court decision from rettspraksis.no." >&2
    echo "Case IDs: HR-2016-1440-A, Rt-1997-550, LA-1999-167, LG-1993-502, etc." >&2
    exit 1
fi

# URL-encode the case ID
ENCODED_ID=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CASE_ID', safe=''))")

URL="https://rettspraksis.no/wiki/${ENCODED_ID}"

CONTENT=$(curl -sL -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" "$URL" 2>/dev/null)

# Check if the page exists
if echo "$CONTENT" | python3 -c "
import sys
content = sys.stdin.read()
if 'Det finnes ingen side med dette navnet' in content or 'noarticletext' in content:
    print('NOT_FOUND')
    sys.exit(0)
print('FOUND')
" 2>/dev/null | grep -q "NOT_FOUND"; then
    echo "Decision not found: $CASE_ID" >&2
    echo "Try searching: ./scripts/search-decisions.sh \"$CASE_ID\"" >&2
    exit 1
fi

echo "$CONTENT" | python3 -c "
import sys, re, html

content = sys.stdin.read()
summary_only = $SUMMARY_ONLY
section_filter = '$SECTION'

# Extract the main content area
main = re.search(
    r'class=\"mw-body-content\"(.*?)(?:<div[^>]*class=\"mw-data-after-content|<footer|<div[^>]*id=\"catlinks)',
    content, re.DOTALL
)
if not main:
    print('Could not extract decision content.', file=sys.stderr)
    sys.exit(1)

text = main.group(1)

# Remove scripts and styles
text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.DOTALL)
text = re.sub(r'<style[^>]*>.*?</style>', '', text, flags=re.DOTALL)

# Convert some structure to readable format
text = re.sub(r'<h[23][^>]*>', '\n\n== ', text)
text = re.sub(r'</h[23]>', ' ==\n', text)
text = re.sub(r'<br\s*/?>', '\n', text)
text = re.sub(r'<li[^>]*>', '\n  - ', text)

# Remove remaining HTML tags
text = re.sub(r'<[^>]+>', '\n', text)

# Unescape HTML entities
text = html.unescape(text)

# Clean up whitespace
text = re.sub(r'\n{3,}', '\n\n', text)
lines = [l.strip() for l in text.strip().split('\n')]

# Remove leading empty line (artifact of the regex)
while lines and (not lines[0] or lines[0] == '>'):
    lines.pop(0)

if summary_only:
    # Extract just the metadata section (up to the actual decision text)
    output = []
    found_forfatter = False
    found_lov = False
    for line in lines:
        output.append(line)
        if line.startswith('Lovhenvisninger:') or 'Lovhenvisninger' in line:
            found_lov = True
        # Stop after lovhenvisninger and its values
        if found_lov and line == '' and len(output) > 5:
            # Include one more non-empty line (the lovhenvisninger values)
            break
        if found_lov and len(output) > 30:
            break
    # If we didn't find lovhenvisninger, just show first 25 lines
    if not found_lov:
        output = lines[:25]
    print('\n'.join(output))
elif section_filter:
    # Show paragraphs around a specific numbered paragraph
    try:
        target = int(section_filter)
    except ValueError:
        target = 0
    # Find paragraphs marked with (N)
    in_range = False
    count = 0
    for line in lines:
        para_match = re.match(r'\((\d+)\)', line)
        if para_match:
            num = int(para_match.group(1))
            if num >= target and num < target + 10:
                in_range = True
                count = 0
            elif num >= target + 10:
                break
        if in_range:
            print(line)
            count += 1
    if count == 0:
        print(f'Paragraph ({section_filter}) not found. Showing full text instead.')
        print('\n'.join(lines))
else:
    print('\n'.join(lines))
"
