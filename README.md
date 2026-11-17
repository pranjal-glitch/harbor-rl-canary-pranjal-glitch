# Harbor RL Submission — Pranjal Srivastava (@pranjal-glitch)

## 1. Loom Walkthrough
- Video URL: PENDING — add the public Loom or unlisted YouTube link after recording.

## 2. Task and Calibration Summary

Task: Payment reconciliation CLI repair.

- Bug 1 (Easy): Incorrect CLI argument access prevents the input CSV from being processed.
- Bug 2 (Medium): Incorrect status accounting, including treating PENDING records as VALID.
- Bug 3 (Hard): Duplicate transaction resolution must compare actual instants across timezone offsets and preserve nanosecond precision.

Dense verifier weights:
- CLI argument handling: 0.20
- Status accounting: 0.30
- Timezone and nanosecond deduplication: 0.50

Calibration:
- NOP: 0.00 — job 2026-11-17__11-45-30
- Oracle/reference solution: 1.00 — job 2026-11-17__13-46-49
- Hardcoded anti-cheat: 0.00 — job 2026-11-17__11-46-32
- Partial oracle (Bug 1 and Bug 2 only): expected 0.50 from the verifier weights; not yet recorded in a live run.

## 3. Baseline and Ablation Results

The required three clean baseline and three clean ablation LLM trials have not been completed on the final task version.

Attempts with Gemini CLI and Groq-backed agents encountered authentication, runtime, or provider rate-limit errors. Earlier Qwen results were obtained before the final nanosecond-precision task change and are not substituted for final-task trials.

No binary/dense advantage values are claimed without the six required valid trials.

## 4. Trajectory Forensics

The Gemini candidate:
- Accessed args.input_file although the parser defines --input.
- Counted PENDING records as VALID.
- Removed timezone information before comparing timestamps.

The candidate failed all three verifier checks. Available agent logs and trajectories are retained in ai_transcripts/ and jobs_summary/.

## 5. Dense Reward and Anti-Cheat

The dense reward gives independent credit for:
- CLI handling (0.20)
- Status accounting (0.30)
- Timestamp deduplication (0.50)

The hardcoded hack prints fixed JSON output instead of reconciling the input CSV. The hardened verifier rejected it with reward 0.00, while the reference solution scored 1.00.

A remaining possible risk is an agent that overfits to known test patterns. Randomized test inputs and additional unseen timestamp cases would further strengthen the verifier.

## 6. AI Workflow

- AI agents attempted: Gemini CLI and Groq-backed Harbor agents.
- Prompt leakage: The task instruction describes the required behavior without identifying implementation lines or giving away the code fix.
- Evidence: ai_transcripts/ and jobs_summary/.

## 7. Outstanding Assignment Requirements

- Three clean baseline LLM trials.
- Three clean ablation LLM trials.
- Binary and dense reward calculations and group-relative advantages for all six trials.
- Live partial-credit demonstration.
- Five-minute unedited Loom walkthrough with public link.

These items are explicitly outstanding; failed runs are not presented as completed experiments.
