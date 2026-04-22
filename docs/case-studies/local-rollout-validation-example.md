# Local Rollout Validation Case Study: Verification Before Confidence

This is the kind of rollout that makes a playbook trustworthy in a live workspace.

## Context

The operator was adopting the playbook into an already-active local OpenClaw environment, not a clean demo repo.

What already existed:
- protected identity and policy files under active use
- daily notes and memory extraction already running
- existing hooks and plugin wiring
- local operational dirt in git that was real, intentional, and not worth pretending away

## What Changed First

The first successful move was not a rewrite. It was a verifier stack.

The rollout added checks for:
- protected-file integrity
- memory readiness
- generic starter-loop health
- brownfield-specific assumptions

That created a repeatable path:

```bash
reference/scripts/integrity-check init
reference/scripts/integrity-check check
reference/scripts/verify-memory-readiness
reference/scripts/verify
reference/scripts/verify-brownfield
reference/scripts/verify-local
```

## Why This Mattered

The docs were useful, but the rollout only felt operationally real once the checks existed.

Three practical benefits showed up immediately:
1. conversational claims stopped being enough
2. regressions became easier to localize
3. brownfield adoption stopped feeling like a leap of faith

## Runtime Truth Over Manifest Theory

One lesson was especially sharp: plugin manifests and config fragments were not enough proof.

For observability and runtime behavior, the operator had to validate:
- the actual runtime path used by the system
- whether `diagnostics-otel` was really active
- whether the collector wiring produced real output

That changed the documentation stance from "the manifest says this should work" to "the runtime proves this works."

## When Runtime Drift Gets Personal

One of the sharper Codex-era lessons was that a live system can fail in ways the config file does not confess.

The rollout had to deal with failure classes like:
- the intended runtime path being different from the runtime path actually in use
- stale pinned sessions preserving old behavior after config was corrected
- embedded auth-bridge state becoming incomplete even though the top-level auth story looked fine
- approval prompts or auth errors coming from old app-server threads rather than current policy

That forced a stricter operational standard:
- verify the active runtime path, not just the configured one
- verify bridge/auth completeness, not just provider selection
- treat stale session state as part of the runtime surface
- verify again after restart or update, because drift loves restarts

This is exactly why the playbook leans so hard on runtime truth over manifest theory. Production failures rarely care which file looked convincing in a code review.

## Delegation Governance

Sub-agent guidance also became more useful after governance was made explicit.

The local rollout treated these as mandatory:
- every delegated run had a tracked parent task
- completion claims were followed by diff and test verification
- risky or overlapping delegated edits needed clear scope boundaries

This made delegation auditable instead of vibes-based.

## Outcome

The workspace did not become pristine. It became legible.

That was the win:
- safer protected-file handling
- verifiable memory readiness
- clear brownfield checks
- better discipline around delegated work

The playbook earned trust because the rollout produced evidence, not because the docs sounded confident.
