# Harbor RL Submission — Pranjal Srivastava (@pranjal-glitch)
https://www.loom.com/share/7aee545aa8b54d1ba7156533d16cf79e
**GitHub Repository:** [harbor-rl-canary-pranjal-glitch](https://github.com/pranjal-glitch/harbor-rl-canary-pranjal-glitch)

## 1. Loom Walkthrough Video

- **Video URL:** Pending recording.
- **Video format:** Unedited screen recording, under 5 minutes.
- **Sharing:** Anyone with the link can view.

The walkthrough will demonstrate the task implementation, live reward verification, anti-cheat testing, trajectory analysis, and dense reward design.

## 2. Task and Calibration Summary

### Task Overview

This project implements a Harbor coding environment based on a Python payment reconciliation CLI application.

The application reads a CSV containing payment transactions and generates a JSON summary with:

- `total_valid_amount`
- `valid_count`
- `failed_count`

### Three Deliberately Introduced Bugs

| Bug | Difficulty | Description | Dense Reward |
|---|---|---|---:|
| Bug 1 | Easy | CLI argument handling | 0.20 |
| Bug 2 | Medium | Transaction status accounting and calculation | 0.30 |
| Bug 3 | Hard | Timezone-aware timestamp deduplication with nanosecond precision | 0.50 |
| **Total** | | | **1.00** |

### Bug 3: Edge Case

The reconciliation application must compare timestamps by their actual instant, even when timestamps have different timezone offsets.

It must also preserve fractional-second precision up to nine digits. When two records have the same transaction ID and represent the same instant, the later CSV row takes precedence.

The reference solution uses integer nanoseconds for timestamp comparison to avoid losing precision through Python datetime's microsecond resolution.

### Calibration Results

| Agent / Test | Expected Reward | Verified Reward |
|---|---:|---:|
| NOP | 0.00 | 0.00 |
| Oracle using `solve.sh` | 1.00 | 1.00 |
| Oracle using `hack.sh` | 0.00 | 0.00 |
| Partial Oracle (Bug 1 and Bug 2 fixed, Bug 3 broken) | 0.50 | Pending live demonstration |

The NOP, Oracle, and anti-cheat results were verified using Harbor. The partial-credit Oracle demonstration remains to be recorded and verified.

## 3. Baseline, Ablation and RL Advantage Analysis

### Experiment Configuration

The assignment requires:

- Baseline: Three LLM trials using `terminus-2`.
- Ablation: Three additional LLM trials using the same model.
- One controlled task change between the two runs.
- Binary and dense rewards calculated for every trial.

**Experiment status:** The required six clean LLM trials have not yet been completed successfully on the final nanosecond-precision task. Previous provider and rate-limit failures are not counted as valid trials.

### Results Table

| Run | Trial | Binary Reward | Dense Reward | Binary Advantage | Dense Advantage |
|---|---|---:|---:|---:|---:|
| Baseline | 1 | Pending | Pending | Pending | Pending |
| Baseline | 2 | Pending | Pending | Pending | Pending |
| Baseline | 3 | Pending | Pending | Pending | Pending |
| Ablation | 1 | Pending | Pending | Pending | Pending |
| Ablation | 2 | Pending | Pending | Pending | Pending |
| Ablation | 3 | Pending | Pending | Pending | Pending |

### Group Means

| Metric | Baseline | Ablation |
|---|---:|---:|
| Mean Binary Reward | Pending | Pending |
| Mean Dense Reward | Pending | Pending |

### Advantage Calculation

The advantage for each trial is calculated as:

**Advantage = Trial Reward − Group Mean Reward**

Binary advantage uses the binary reward, while dense advantage uses the dense reward.

A positive advantage indicates that a trial performed better than its group average. A negative advantage indicates performance below the group average.

No numerical trial rewards, group means, or advantages are reported until the six required valid trials are completed.

## 4. Trajectory Forensics and Ablation

### Baseline Trajectory Analysis

Harbor records agent actions in `trajectory.json`, including commands executed, files inspected, code modifications, and testing behavior.

Trajectory analysis is intended to identify:

- Whether the agent correctly understood the task instructions.
- Whether it fixed the CLI argument handling issue.
- Whether it correctly handled transaction statuses and calculations.
- Whether it tested timezone and nanosecond timestamp edge cases.
- Whether it stopped before validating the difficult cases.

Previous unsuccessful agent attempts showed that incorrect CLI argument handling, incorrect treatment of PENDING transactions, and timezone normalization can lead to failed verification.

### Ablation Hypothesis

The purpose of the ablation is to test whether one controlled change to the task instructions or environment improves the agent's ability to handle the difficult timestamp edge case.

The baseline and ablation must use the same model and trial configuration, with only one task condition changed.

**Ablation change:** Pending final controlled experiment.

**Ablation result:** Pending three valid trials.

No improvement is claimed without experimental evidence.

## 5. Dense Reward and Anti-Cheat Design

### Dense Reward Weights

The verifier evaluates three independent checks:

| Check | Weight |
|---|---:|
| CLI argument handling | 0.20 |
| Status accounting and calculation | 0.30 |
| Timestamp deduplication and precision | 0.50 |
| **Total** | **1.00** |

The verifier calculates the score by adding the weights of the checks that pass.

This approach provides partial feedback instead of treating every incomplete solution as an identical zero.

### How `hack.sh` Attempts to Cheat

The hack script demonstrates a simple reward-hacking strategy.

It replaces the actual reconciliation behavior with hardcoded JSON output. This ignores the supplied CSV and does not implement genuine transaction processing.

### How the Verifier Blocks the Shortcut

The hardened verifier uses generated test inputs and checks the actual output against the expected reconciliation results.

This prevents a fixed JSON response from receiving credit merely because it matches one predictable test case.

The anti-cheat test was run through Harbor's Oracle agent and produced a reward of 0.00.

### Remaining Reward-Hacking Risk

A more sophisticated agent might try to overfit its implementation to predictable test patterns rather than implement the general business rules.

Additional randomized inputs, unseen transaction combinations, and edge cases can help reduce this risk.

### Local Optimum Risk

An agent might repeatedly collect the easier rewards from Bug 1 and Bug 2 while avoiding Bug 3 because changing its timestamp logic could break the other functionality.

If this occurs, the reward distribution and task design should be reconsidered to encourage the agent to solve the difficult edge case rather than settle for partial credit.

## 6. AI Tool Workflow

### Tools Used

- ChatGPT for planning, explanations, debugging guidance, and documentation support.
- Gemini CLI and Terminus-2 model attempts during agent evaluation.

Some model attempts encountered provider rate limits or execution errors and are not counted as successful final-task trials.

### Avoiding Prompt Leakage

The task instructions describe the input format, output format, and required business rules.

They do not disclose the exact implementation locations or the specific code changes required to fix the bugs.

The deliberately broken implementation remains in the environment, while the correct implementation is maintained separately in `solution/solve.sh`.

This separation allows an agent to investigate the task without being given the solution directly.

## 7. Submission Repository Structure

The main submission items are:

```text
harbor-rl-canary-pranjal-glitch/
│
├── README.md
│
├── tasks/
│   └── reconcile-bug/
│       ├── task.toml
│       ├── instruction.md
│       ├── environment/
│       │   ├── Dockerfile
│       │   └── reconcile.py
│       ├── solution/
│       │   ├── solve.sh
│       │   └── hack.sh
│       └── tests/
│           └── test.sh
│
├── jobs_summary/
│   └── Harbor result and trajectory files
│
└── ai_transcripts/
    └── AI coding and agent records
```

## 8. Outstanding Items

- [ ] Complete three valid baseline LLM trials.
- [ ] Implement and document one controlled ablation change.
- [ ] Complete three valid ablation LLM trials.
- [ ] Calculate binary and dense rewards for all six trials.
- [ ] Calculate group means and advantages.
- [ ] Verify and record the partial Oracle reward of 0.50.
- [ ] Record the five-minute Loom walkthrough.
- [ ] Add the Loom URL to this README.
- [ ] Ensure the AI coding tool's exported chat history is included.

---

**Submitted by:** Pranjal Srivastava  
**GitHub:** [@pranjal-glitch](https://github.com/pranjal-glitch)
