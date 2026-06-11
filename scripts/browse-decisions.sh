#!/usr/bin/env bash
# Browse recent court decisions from the Lovdata register.
# Shows summaries and metadata (stikkord) for recent decisions.
#
# Note: This browses the register chronologically. It does NOT search by topic.
# For topic search, use search-decisions.sh instead.
#
# Usage:
#   ./browse-decisions.sh                              Latest 20 decisions
#   ./browse-decisions.sh --court HRA                  Filter by court
#   ./browse-decisions.sh --court LRA --offset 20      Paginate
#
# Courts:
#   HRA   = Hoyesterett
#   LRA   = Alle lagmannsretter
#   LAA   = Agder lagmannsrett
#   LBA   = Borgarting lagmannsrett
#   LEA   = Eidsivating lagmannsrett
#   LFRA  = Frostating lagmannsrett
#   LGA   = Gulating lagmannsrett
#   LHA   = Haalogaland lagmannsrett
#   TRA   = Tingrettene
#   JSR   = Jordskifterettene
#   EMDN  = Menneskerettsdomstolen

set -euo pipefail

COURT="*"
OFFSET=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --court) COURT="$2"; shift 2 ;;
        --offset) OFFSET="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

URL="https://lovdata.no/register/avgj%C3%B8relser?verdict=${COURT}&offset=${OFFSET}"

echo "=== Lovdata Register: Recent Decisions (court=${COURT}, offset=${OFFSET}) ==="
echo ""

curl -sL -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    "$URL" 2>/dev/null | python3 -c "
import sys, re, html

content = sys.stdin.read()

# Find all decision articles
entries = re.findall(r'<article[^>]*>(.*?)</article>', content, re.DOTALL)

if not entries:
    print('No decisions found.')
    sys.exit(0)

for entry in entries:
    text = re.sub(r'<[^>]+>', '\n', entry)
    text = html.unescape(text)
    lines = [l.strip() for l in text.split('\n') if l.strip()]

    if len(lines) >= 4:
        case_id = lines[0]
        summary = lines[1]
        stikkord = lines[2] if lines[2].startswith('Stikkord:') else ''
        date = ''
        court_name = ''
        for l in lines:
            if re.match(r'^\d{4}-\d{2}-\d{2}$', l):
                date = l
            elif any(w in l for w in ['Høyesterett', 'lagmannsrett', 'tingrett', 'jordskifterett']):
                court_name = l

        print(f'{case_id}  ({date})')
        print(f'  {court_name}')
        if stikkord:
            print(f'  {stikkord}')
        print(f'  {summary[:200]}')
        print()

print(f'--- {len(entries)} decisions shown (offset {$OFFSET}) ---')
print(f'Next page: ./scripts/browse-decisions.sh --court $COURT --offset {$OFFSET + len(entries)}')
"
