---
name: lovdata
description: Look up Norwegian laws (gjeldende lover) using Lovdata's public data. Search by title or full text, read specific laws or sections, and list the structure of any law. Use when the user asks about Norwegian legislation, specific law paragraphs, or legal questions about Norway.
---

# Lovdata - Norwegian Law Lookup

Search and read all current Norwegian laws using Lovdata's publicly available
dataset (NLOD 2.0 license). The data contains 741 laws in structured HTML/XML
format, sourced from https://api.lovdata.no/v1/publicData/get/gjeldende-lover.tar.bz2.

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

## Workflow

1. If the user asks about a specific law or topic, first **search** for it.
2. Then **list sections** to understand the law's structure.
3. Then **read** the relevant section(s) to get the actual text.
4. Present the legal text accurately. Always cite the specific paragraph
   (e.g. "straffeloven $ 371") and note that this is the current consolidated
   version from Lovdata's public dataset.
5. Do not invent or hallucinate legal text. If a section is not found, say so.

## Data refresh

The index and law files are pre-built in this skill. To refresh with the latest
data from Lovdata, run:

```bash
./scripts/build-index.sh --force
```
