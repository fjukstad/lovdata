# Lovdata

[Agent skill](https://agentskills.io) for looking up Norwegian laws using
Lovdata's public dataset (NLOD 2.0 license). Works with any coding agent that
supports the Agent Skills standard.

## Setup

Clone this repo into your agent's skills directory:

```bash
# Examples:
git clone https://github.com/fjukstad/lovdata.git ~/.pi/agent/skills/lovdata
git clone https://github.com/fjukstad/lovdata.git ~/.claude/skills/lovdata
git clone https://github.com/fjukstad/lovdata.git ~/.codex/skills/lovdata
git clone https://github.com/fjukstad/lovdata.git ~/.agents/skills/lovdata
```

Then download and extract the law data:

```bash
cd <skill-directory>/lovdata
./scripts/build-index.sh
```

## Usage

The skill activates automatically when you ask about Norwegian laws. See
[SKILL.md](SKILL.md) for available scripts and common law references.
