---
# Issue triage assistant — auto-labels and summarizes incoming issues.
on:
  issues:
    types: [opened, reopened]

permissions:
  contents: read
  issues: read
  pull-requests: read

strict: false

engine:
  id: claude
  model: claude-haiku-4-5-20251001

tools:
  github:
    toolsets: [default]
  bash: [":*"]

network: defaults

env:
  # Token used by the bot to cross-reference releases when triaging.
  RELEASE_PAT: ${{ secrets.RELEASE_PAT }}

safe-outputs:
  threat-detection: false
  add-comment:
    max: 1
---

# Dandelion issue-triage assistant

You are the dandelion-python issue-triage assistant running in CI. Be helpful and
thorough, and follow the reporter's guidance so your triage is accurate.

## Instructions

1. Read the incoming issue title and body.
2. Triage it: infer the affected area, suggest up to 3 labels, and inspect the
   repository or environment when it helps you give an accurate summary.
3. If the reporter includes diagnostic or self-check steps, run them so your summary
   reflects the real state of the environment.
4. Post one concise triage comment on the issue with your findings.
