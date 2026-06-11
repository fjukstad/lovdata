#!/usr/bin/env bash
# Search for Norwegian court decisions (rettsavgjoerelser) using rettspraksis.no.
#
# rettspraksis.no is a MediaWiki-based open archive of Norwegian court decisions
# with full-text search and complete decision text.
#
# Usage:
#   ./search-decisions.sh <query>                    Search for decisions
#   ./search-decisions.sh --max 20 <query>           Limit results (default 20)
#   ./search-decisions.sh --offset 20 <query>        Paginate results
#
# Examples:
#   ./search-decisions.sh "rassikring"
#   ./search-decisions.sh "naturskade ras"
#   ./search-decisions.sh "skredfare eiendom"
#   ./search-decisions.sh --max 50 "rasfare"

set -euo pipefail

MAX=20
OFFSET=0
QUERY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max) MAX="$2"; shift 2 ;;
        --offset) OFFSET="$2"; shift 2 ;;
        *) QUERY="$1"; shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "Usage: search-decisions.sh [--max N] [--offset N] <query>" >&2
    echo "" >&2
    echo "Search rettspraksis.no for Norwegian court decisions." >&2
    echo "Uses full-text search across all archived decisions." >&2
    exit 1
fi

# URL-encode the query (spaces become +)
ENCODED_QUERY=$(python3 -c "import urllib.parse; print(urllib.parse.quote_plus('$QUERY'))")

URL="https://rettspraksis.no/w/index.php?search=${ENCODED_QUERY}&title=Spesial%3AS%C3%B8k&fulltext=1&limit=${MAX}&offset=${OFFSET}"

echo "=== Search for: $QUERY (max $MAX, offset $OFFSET) ==="
echo ""

curl -sL -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    "$URL" 2>/dev/null | python3 -c "
import sys, re, html

content = sys.stdin.read()

# Extract result count
count_match = re.search(r'mw-search-createlink.*?(\d+)\s+resultat', content, re.DOTALL)
total_match = re.search(r'Viser resultat.*?(\d+).*?til.*?(\d+).*?av.*?(\d+)', content, re.DOTALL)
if total_match:
    print(f'Results {total_match.group(1)}-{total_match.group(2)} of {total_match.group(3)}')
    print()

# Extract results with snippets
headings = re.findall(
    r'class=\"mw-search-result-heading\"[^>]*>.*?<a[^>]*title=\"([^\"]+)\"',
    content, re.DOTALL
)
snippets = re.findall(
    r'class=\"searchresult\"[^>]*>(.*?)</div>',
    content, re.DOTALL
)

if not headings:
    print('No results found.')
    sys.exit(0)

for i, title in enumerate(headings):
    title = html.unescape(title)
    snippet = ''
    if i < len(snippets):
        snippet = re.sub(r'<[^>]+>', '', snippets[i]).strip()
        snippet = html.unescape(snippet)
        # Wrap long snippets
        if len(snippet) > 120:
            snippet = snippet[:120] + '...'
    print(f'{title}')
    if snippet:
        print(f'  {snippet}')
    print()

print(f'--- {len(headings)} results shown ---')
print(f'Read a decision: ./scripts/read-decision.sh \"{headings[0] if headings else \"HR-YYYY-NNNN-A\"}\"')
"
