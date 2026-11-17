Fix the payment reconciliation tool located at `/app/reconcile.py`.

### Application Overview
`/app/reconcile.py` is a Python CLI tool that parses transaction records from a CSV file and outputs a reconciliation summary as JSON to standard output.

### Input Specification
The application must accept an input CSV file path via the `--input` command-line argument:
```bash
python /app/reconcile.py --input /path/to/transactions.csv
```

The CSV file contains the following header columns:
- `tx_id`: Unique identifier for the transaction.
- `timestamp`: ISO-8601 timestamp with an explicit timezone offset and optional fractional seconds of 1 to 9 digits (nanosecond precision), e.g. `2026-05-01T12:00:00+00:00`, `2026-05-01T08:00:00.123456789-04:00`, or `2026-05-01T16:00:00Z`.
- `amount`: Numerical transaction amount string (e.g., `12.50`, `100.005`).
- `status`: Transaction status string (`VALID`, `FAILED`, or `PENDING`).

### Business Requirements
1. **Deduplication**:
   - Deduplicate records by `tx_id`.
   - For duplicate entries of the same `tx_id`, keep only the record with the latest actual chronological timestamp.
   - Timestamps must be compared as actual physical instants in time across varying timezone offsets.
   - Preserve and compare fractional-second precision up to all 9 digits (nanoseconds). Do not truncate timestamps to Python datetime's microsecond precision.
   - If two or more duplicate records represent the exact same chronological instant, the last occurrence in the CSV file takes precedence.
   - A timestamp with more fractional-second digits may be later or earlier than another timestamp even when their first 6 fractional digits are identical.

2. **Status Accounting**:
   - Only surviving deduplicated records are evaluated.
   - Records with status `VALID` contribute their `amount` to `total_valid_amount` and increment `valid_count` by 1.
   - Records with status `FAILED` increment `failed_count` by 1 and do not contribute to `total_valid_amount`.
   - Records with status `PENDING` contribute to neither the amounts nor the counts.

3. **Monetary Precision**:
   - Perform monetary arithmetic using precise decimal computation to avoid floating-point inaccuracies.
   - The final `total_valid_amount` must be rounded to two decimal places using the `ROUND_HALF_UP` rounding mode.

### Output Specification
Print a single valid JSON object to standard output containing exactly these three keys:
- `total_valid_amount`: Number representing the final rounded total amount of valid transactions.
- `valid_count`: Integer count of valid transactions.
- `failed_count`: Integer count of failed transactions.

Example output:
```json
{"total_valid_amount": 125.5, "valid_count": 3, "failed_count": 1}
```
