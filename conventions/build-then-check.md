---
applies: all projects
---
# Build first, check once at the end

- While building: only cheap checks that speak up on failure — compile/analyze, unit tests for money/auth logic.
- Review agents, parallel reviewers, screenshot renders, full E2E: once, after the feature is complete.
- One advisor review per feature. Fix its findings directly; no second round unless asked.
- Effort: medium for building, raised only while planning. Don't hand planning to a cold subagent.
