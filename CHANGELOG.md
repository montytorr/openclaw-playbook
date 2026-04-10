# Changelog

All notable changes to this project should be documented in this file.

This changelog uses a lightweight Keep a Changelog style and is intentionally human-written.

## [Unreleased]

### Added
- `CHANGELOG.md` to track project history in a lightweight, human-maintained format.
- Root `VERSION` file for simple repo versioning.
- CI release-hygiene check that requires `VERSION` and `CHANGELOG.md` updates when meaningful project files change.

### Changed
- README now points contributors at changelog upkeep as part of normal release hygiene.
- Release hygiene guidance now documents lightweight semver-style bumps for the repo.
- Clarified that Spark should only be treated as routable when a strong account-scoped signal proves it is actually usable, not merely because it appears in a model list.
- Tightened Codex cron/config guidance so unknown Spark availability falls back to `gpt-5.3-codex`.

## [2026-04-10]

### Changed
- Realigned telemetry guidance around bundled `diagnostics-otel`.
- Strengthened brownfield adoption guidance around verification-first rollout.
- Added a clearer runtime-truth-over-manifest stance for live systems.
- Expanded delegation governance and post-sub-agent verification guidance.
- Added starter verifier scripts for integrity checks, memory readiness, and local rollout validation.

## [2026-04-09]

### Changed
- Updated Codex routing guidance.
- Realigned memory and browser playbook guidance.

## [2026-04-08]

### Changed
- Framed the memory system more explicitly as an LLM wiki for humans and agents.

## [2026-04-07]

### Added
- Reactor architecture guidance and tighter The Wall scoping.

## [2026-04-05]

### Added
- Brownfield adoption guidance for active-workspace rollouts.
- Brownfield adapter example, verifier, and migration case study.

## [2026-04-04]

### Added
- Starter references, one-pager, and validation guide.
- Hardened reference verification and setup flow.

### Changed
- Fixed task CLI contract issues and improved idempotent references.
- Aligned setup, repo URL, lean-start path, and security tone.
- Documented Codex-only runtime setup and provider migration guidance.

## [2026-04-03]

### Added
- Initial public playbook release with core chapters, templates, schemas, and setup flow.
- Expanded the playbook with sub-agents, skills, context management, project template, and cross-references.
- Added the infrastructure and networking chapter.

### Changed
- Hardened public docs with private-first guidance and high-risk infra warnings.
- Clarified hybrid memory architecture and observation DB schema.
- Cleaned up repo defaults with `.gitignore` and generic `agent.db` references.
