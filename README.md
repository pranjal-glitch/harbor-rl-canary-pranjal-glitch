# Harbor RL: Payment Reconciliation Bug

## Task
Repair a Python CSV payment-reconciliation CLI.

The task evaluates:
1. CLI input argument handling — 0.20
2. Status accounting — 0.30
3. Timezone-aware deduplication with nanosecond precision — 0.50

## Implementation
- Original buggy application: tasks/reconcile-bug/environment/reconcile.py
- Reference solution: tasks/reconcile-bug/solution/solve.sh
- Hardcoded anti-cheat solution: tasks/reconcile-bug/solution/hack.sh
- Verifier: tasks/reconcile-bug/tests/test.sh
- Task specification: tasks/reconcile-bug/instruction.md

The reference solution uses decimal arithmetic with ROUND_HALF_UP and compares timestamps at nanosecond precision.

## Validation
Latest Oracle calibration:
- Job: 2026-11-17__13-46-49
- Reward: 1.000
- Exceptions: 0

Other calibration evidence:
- NOP baseline: 0.000, job 2026-11-17__11-45-30
- Hardcoded anti-cheat test: 0.000, job 2026-11-17__11-46-32

## LLM experiments
The required three clean baseline and three clean ablation LLM trials have not been completed.
Attempts using Gemini CLI and Groq-backed agents encountered agent errors or provider rate limits. These are documented in reports/EXPERIMENT_REPORT.md and ai_transcripts/.

No failed or incomplete run is represented as a successful experiment.

## Reproduction
Run the reference validation:

    harbor run -p ./tasks/reconcile-bug -a oracle

Run the NOP calibration:

    harbor run -p ./tasks/reconcile-bug -a nop

## Evidence
- reports/EXPERIMENT_REPORT.md: experiment status and limitations
- jobs_summary.csv: extracted Harbor job results
- ai_transcripts/: available agent output logs
