---
name: lovdata
description: Look up Norwegian laws (gjeldende lover) and court decisions (rettsavgjoerelser/dommer) using Lovdata's public data and rettspraksis.no. Search by title or full text, read specific laws or sections, list the structure of any law, search and read court decisions. Use when the user asks about Norwegian legislation, specific law paragraphs, court cases, or legal questions about Norway.
---

# Lovdata - Norwegian Law and Case Law Lookup

Search and read all current Norwegian laws using Lovdata's publicly available
dataset (NLOD 2.0 license). The data contains 741 laws in structured HTML/XML
format, sourced from https://api.lovdata.no/v1/publicData/get/gjeldende-lover.tar.bz2.

Search and read court decisions (rettsavgjoerelser) from rettspraksis.no, an
open archive of Norwegian court decisions with full text. Browse recent decisions
via the Lovdata register.

The pre-built index lives in [references/index.tsv](references/index.tsv).
The extracted law XML files live in `data/nl/`.

## Scripts

All scripts live in the `scripts/` directory relative to this file.

### Search for laws

Search the index (titles and short titles):

```bash
./scripts/search-laws.sh "arbeidsmiljø"
```

Full-text search across all law files:

```bash
./scripts/search-laws.sh --fulltext "personopplysning"
./scripts/search-laws.sh --fulltext --max 10 "varslingsplikt"
```

### List sections in a law

Show the table of contents / structure of a specific law:

```bash
./scripts/list-sections.sh "lov/2005-05-20-28"
```

### Read a law

Read the full law text (plain text, HTML stripped):

```bash
./scripts/read-law.sh "lov/2005-05-20-28"
```

Read just the metadata header:

```bash
./scripts/read-law.sh "lov/2005-05-20-28" --header
```

Read a specific section or paragraph:

```bash
./scripts/read-law.sh "lov/2005-05-20-28" --section "§371"
./scripts/read-law.sh "lov/2005-05-20-28" --section "kap30"
```

### File identification

All scripts accept flexible identifiers:

- refID: `lov/2005-05-20-28`
- Filename: `nl-20050520-028.xml`
- Short form: `20050520-028`

### Common refIDs

| Law | refID |
|-----|-------|
| Grunnloven | `lov/1814-05-17` |
| Grannelova (naboloven) | `lov/1961-06-16-15` |
| Straffeloven | `lov/2005-05-20-28` |
| Straffeprosessloven | `lov/1981-05-22-25` |
| Arbeidsmiljoeloven | `lov/2005-06-17-62` |
| Folketrygdloven | `lov/1997-02-28-19` |
| Forvaltningsloven | `lov/1967-02-10` |
| Plan- og bygningsloven | `lov/2008-06-27-71` |
| Aksjeloven | `lov/1997-06-13-44` |
| Skatteloven | `lov/1999-03-26-14` |
| Personopplysningsloven | `lov/2018-06-15-38` |
| Naturskadeloven | `lov/1994-03-25-7` |
| Naturskadeerstatningsloven | `lov/2014-08-15-59` |
| Husleieloven | `lov/1999-03-26-17` |
| Avhendingslova | `lov/1992-07-03-93` |
| Skadeerstatningsloven | `lov/1969-06-13-26` |

### Search court decisions

Search rettspraksis.no for court decisions by topic:

```bash
./scripts/search-decisions.sh "rassikring"
./scripts/search-decisions.sh --max 50 "rasfare"
./scripts/search-decisions.sh "naturskade ras"
./scripts/search-decisions.sh "skredfare eiendom"
```

### Read a court decision

Read the full text of a decision from rettspraksis.no:

```bash
./scripts/read-decision.sh "HR-2016-1440-A"
./scripts/read-decision.sh "LA-1999-167" --summary
./scripts/read-decision.sh "Rt-1997-550"
./scripts/read-decision.sh "LG-1993-502" --section 5
```

Case ID formats:
- `HR-YYYY-NNNN-A/S/U` -- Hoyesterett (2008+)
- `Rt-YYYY-PAGE` -- Hoyesterett (pre-2008, Rettstidende)
- `LA/LB/LE/LF/LG/LH-YYYY-NNNNN` -- Lagmannsrettene
- `RG-YYYY-PAGE` -- Rettens Gang (older collection)
- `T*-YYYY-NNNNN` -- Tingrettene

### Browse recent decisions

Browse the Lovdata register for recent decisions with summaries:

```bash
./scripts/browse-decisions.sh
./scripts/browse-decisions.sh --court HRA
./scripts/browse-decisions.sh --court LRA --offset 20
```

Courts: `HRA` (Hoyesterett), `LRA` (alle lagmannsretter), `LAA` (Agder),
`LBA` (Borgarting), `LEA` (Eidsivating), `LFRA` (Frostating), `LGA` (Gulating),
`LHA` (Haalogaland), `TRA` (tingrettene), `JSR` (jordskifterettene).

## Workflow

### For law questions

1. If the user asks about a specific law or topic, first **search** for it.
2. Then **list sections** to understand the law's structure.
3. Then **read** the relevant section(s) to get the actual text.
4. Present the legal text accurately. Always cite the specific paragraph
   (e.g. "straffeloven $ 371") and note that this is the current consolidated
   version from Lovdata's public dataset.
5. Do not invent or hallucinate legal text. If a section is not found, say so.

### For court decisions

1. **Search** rettspraksis.no for relevant decisions using topic keywords.
2. Try multiple related search terms (e.g. "rassikring", "rasfare",
   "skredfare", "naturskade ras") since the full-text search is literal.
3. **Read** the summary first (`--summary`) to check relevance.
4. **Read** the full text of relevant decisions.
5. Always cite the case ID (e.g. "Rt-1997-550", "HR-2016-1440-A").
6. Note that rettspraksis.no is a community archive and may not have all
   decisions. For the very latest decisions, **browse** the Lovdata register.

## Data refresh

The index and law files are pre-built in this skill. To refresh with the latest
data from Lovdata, run:

```bash
./scripts/build-index.sh --force
```
