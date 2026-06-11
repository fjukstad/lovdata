# Lovdata

[Pi](https://github.com/badlogic/pi) skill for looking up Norwegian laws using
Lovdata's public dataset (NLOD 2.0 license).

## Setup

Clone this repo and add it to your pi skills directory:

```bash
git clone https://github.com/fjukstad/lovdata.git ~/.pi/agent/skills/lovdata
```

Then download and extract the law data:

```bash
cd ~/.pi/agent/skills/lovdata
./scripts/build-index.sh
```

## Usage

The skill activates automatically when you ask pi about Norwegian laws. You can
also invoke it directly:

```
/skill:lovdata hva sier straffeloven om bedrageri?
```
