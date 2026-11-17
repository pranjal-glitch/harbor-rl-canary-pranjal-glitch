# Experiment Report

## Task objective
Evaluate whether agents can repair a Python payment reconciliation CLI with weighted verifier checks:
- CLI argument handling: 0.20
- Status accounting: 0.30
- Timezone deduplication and nanosecond precision: 0.50

## Final task validation
The strengthened task was calibrated with the following jobs:

| Job | Agent | Reward | Exceptions | Interpretation |
|---|---|---:|---:|---|
| 2026-11-17__11-43-24 | Oracle | 1.00 | 0 | Oracle calibration passed |
| 2026-11-17__11-45-30 | NOP | 0.00 | 0 | NOP calibration passed |
| 2026-11-17__11-46-32 | Oracle with hack.sh substituted | 0.00 | 0 | Hardcoded-output anti-cheat check passed |
| 2026-11-17__13-46-49 | Oracle | 1.00 | 0 | Latest final validation passed |

## LLM attempts
The following attempts were made, but none qualifies as a clean completed LLM trial on the strengthened task:

- Qwen via Terminus-2: provider token/rate limits and incomplete execution.
- Allam via Terminus-2: provider token/rate limits.
- Gemini CLI: Vertex AI/API-key authentication configuration failure; the generated candidate also failed the verifier.
- Qwen Coder and OpenHands: agent installation/runtime failures.

The Gemini candidate had three verifier failures:
- CLI argument used args.input_file instead of args.input.
- PENDING records were counted as VALID.
- Timezone offsets were stripped before timestamp comparison.

The required three baseline and three ablation clean LLM trials remain outstanding.

## Reward and advantage calculations
No baseline/ablation advantage values are reported because there are not enough valid completed LLM trials to calculate them honestly.

For a completed group of rewards, the usual group-relative advantage is:

    advantage_i = reward_i - mean(group_rewards)

No such group is claimed here.

## Limitations and next steps
1. Obtain three clean baseline LLM trials on the final task version.
2. Obtain three clean ablation LLM trials with the specified ablation.
3. Inspect and preserve their trajectories.
4. Calculate reward and advantage values from those completed trials.
5. Record a Loom walkthrough and submit the repository to the designated GitHub destination.
