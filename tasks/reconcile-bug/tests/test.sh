#!/bin/bash
set -u

REWARD_FILE="${HARBOR_REWARD_FILE:-/logs/verifier/reward.txt}"
export REWARD_FILE

mkdir -p "$(dirname "$REWARD_FILE")"
printf '0.00\n' > "$REWARD_FILE"

python3 - <<'PY'
import csv
import json
import math
import os
import random
import secrets
import subprocess
import sys
import tempfile
import importlib.util

from datetime import datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP

REWARD_FILE = os.environ["REWARD_FILE"]
APP = os.environ.get("RECONCILE_APP_PATH", "/app/reconcile.py")

WEIGHTS = {
    "check1": Decimal("0.20"),
    "check2": Decimal("0.30"),
    "check3": Decimal("0.50"),
}

rng = random.Random(secrets.randbits(64))


def write_reward(score):
    with open(REWARD_FILE, "w", encoding="utf-8") as f:
        f.write(f"{score:.2f}\n")


if not os.path.isfile(APP):
    print(f"FATAL: Application not found: {APP}", file=sys.stderr)
    sys.exit(1)


def make_csv(rows):
    f = tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".csv",
        newline="",
        encoding="utf-8",
        delete=False
    )

    try:
        writer = csv.DictWriter(
            f,
            fieldnames=["tx_id", "timestamp", "amount", "status"]
        )
        writer.writeheader()
        writer.writerows(rows)
        return f.name
    finally:
        f.close()


# Independent reference implementation with nanosecond precision.
def reference_timestamp_ns(value):
    import re

    match = re.fullmatch(
        r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})"
        r"(?:\.(\d{1,9}))?"
        r"(Z|[+-]\d{2}:\d{2})",
        value.strip()
    )
    if not match:
        raise ValueError(f"Invalid timestamp: {value}")

    base, fraction, zone = match.groups()
    fraction = fraction or ""
    microseconds = fraction[:6].ljust(6, "0")
    remainder_ns = int(fraction[6:9].ljust(3, "0")) if len(fraction) > 6 else 0

    normalized_zone = "+00:00" if zone == "Z" else zone
    dt_text = base
    if fraction:
        dt_text += "." + microseconds
    dt = datetime.fromisoformat(dt_text + normalized_zone).astimezone(timezone.utc)

    epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
    delta = dt - epoch
    whole_microseconds = (
        (delta.days * 86400 + delta.seconds) * 1_000_000
        + delta.microseconds
    )
    return whole_microseconds * 1000 + remainder_ns


def expected_result(rows):
    latest = {}

    for row in rows:
        tx_id = row["tx_id"]
        ts_ns = reference_timestamp_ns(row["timestamp"])

        record = {
            "ts_ns": ts_ns,
            "amount": Decimal(str(row["amount"])),
            "status": row["status"],
        }

        # Latest absolute nanosecond instant wins.
        # Later CSV row wins only for an exactly equal instant.
        if tx_id not in latest or ts_ns >= latest[tx_id]["ts_ns"]:
            latest[tx_id] = record

    total = Decimal("0")
    valid_count = 0
    failed_count = 0

    for record in latest.values():
        if record["status"] == "VALID":
            total += record["amount"]
            valid_count += 1
        elif record["status"] == "FAILED":
            failed_count += 1

    total = total.quantize(
        Decimal("0.01"),
        rounding=ROUND_HALF_UP
    )

    return {
        "total_valid_amount": total,
        "valid_count": valid_count,
        "failed_count": failed_count,
    }


def run_application(rows, use_cli=False):
    path = make_csv(rows)

    try:
        if use_cli:
            result = subprocess.run(
                [sys.executable, APP, "--input", path],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode != 0:
                raise AssertionError(
                    f"CLI exited {result.returncode}: "
                    f"{result.stderr[:500]}"
                )

            try:
                actual = json.loads(result.stdout)
            except Exception as exc:
                raise AssertionError(
                    f"Invalid JSON output: {result.stdout[:500]}"
                ) from exc

        else:
            spec = importlib.util.spec_from_file_location(
                "reconcile_app",
                APP
            )

            if spec is None or spec.loader is None:
                raise AssertionError("Cannot load application module")

            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)

            actual = module.reconcile(path)

        if not isinstance(actual, dict):
            raise AssertionError("Output must be a dictionary")

        required = {
            "total_valid_amount",
            "valid_count",
            "failed_count"
        }

        if set(actual.keys()) != required:
            raise AssertionError(
                f"Unexpected output keys: {list(actual.keys())}"
            )

        amount = actual["total_valid_amount"]
        valid = actual["valid_count"]
        failed = actual["failed_count"]

        if isinstance(amount, bool) or not isinstance(amount, (int, float)):
            raise AssertionError("Invalid total_valid_amount")

        if isinstance(amount, float) and not math.isfinite(amount):
            raise AssertionError("Non-finite total_valid_amount")

        if isinstance(valid, bool) or not isinstance(valid, int):
            raise AssertionError("Invalid valid_count")

        if isinstance(failed, bool) or not isinstance(failed, int):
            raise AssertionError("Invalid failed_count")

        expected = expected_result(rows)

        if Decimal(str(amount)) != expected["total_valid_amount"]:
            raise AssertionError(
                f"Amount mismatch: expected "
                f"{expected['total_valid_amount']}, got {amount}"
            )

        if valid != expected["valid_count"]:
            raise AssertionError(
                f"valid_count mismatch: expected "
                f"{expected['valid_count']}, got {valid}"
            )

        if failed != expected["failed_count"]:
            raise AssertionError(
                f"failed_count mismatch: expected "
                f"{expected['failed_count']}, got {failed}"
            )

        return True

    finally:
        if os.path.exists(path):
            os.remove(path)


def random_amount():
    mills = rng.randint(1, 500000)
    return str(Decimal(mills) / Decimal("1000"))


def random_timestamp():
    base = datetime(2026, 6, 1, 12, 0, tzinfo=timezone.utc)

    offset = rng.choice([-300, -240, 0, 60, 180, 330])

    return base.astimezone(
        timezone(timedelta(minutes=offset))
    ).isoformat()


# CHECK 1: CLI argument handling.
def check1():
    statuses = [
        "VALID", "FAILED", "PENDING",
        "VALID", "FAILED", "PENDING",
        "VALID", "FAILED", "PENDING"
    ]

    rows = []

    for i, status in enumerate(statuses):
        rows.append({
            "tx_id": f"CLI_{secrets.token_hex(8)}_{i}",
            "timestamp": random_timestamp(),
            "amount": random_amount(),
            "status": status
        })

    rng.shuffle(rows)

    # Only this check uses the CLI.
    return run_application(rows, use_cli=True)


# CHECK 2: Status accounting and rounding.
def check2():
    rows = []

    for i in range(35):
        rows.append({
            "tx_id": f"STATUS_{i}_{secrets.token_hex(4)}",
            "timestamp": random_timestamp(),
            "amount": random_amount(),
            "status": rng.choice([
                "VALID", "FAILED", "PENDING"
            ])
        })

    rows.extend([
        {
            "tx_id": "STATUS_HALF_UP",
            "timestamp": "2026-06-01T10:00:00+00:00",
            "amount": "25.125",
            "status": "VALID"
        },
        {
            "tx_id": "STATUS_PENDING",
            "timestamp": "2026-06-01T10:00:00+00:00",
            "amount": "999.99",
            "status": "PENDING"
        },
        {
            "tx_id": "STATUS_FAILED",
            "timestamp": "2026-06-01T10:00:00+00:00",
            "amount": "50.00",
            "status": "FAILED"
        }
    ])

    # Direct function invocation keeps this independent of CLI.
    return run_application(rows, use_cli=False)


# CHECK 3: Timezone deduplication and exact-instant tie-breaking.
def check3():
    rows = []

    # Nanosecond precision: the first row is later, despite appearing first.
    # A microsecond-only parser incorrectly treats these timestamps as equal
    # and lets the second (older) CSV row win.
    rows.extend([
        {
            "tx_id": "NANOSECOND_PRECISION",
            "timestamp": "2026-06-01T12:00:00.1234568+00:00",
            "amount": "80.00",
            "status": "VALID"
        },
        {
            "tx_id": "NANOSECOND_PRECISION",
            "timestamp": "2026-06-01T12:00:00.1234567+00:00",
            "amount": "90.00",
            "status": "FAILED"
        }
    ])

    # The same instant represented with different timezone offsets and
    # nanosecond precision: the later CSV row must win.
    rows.extend([
        {
            "tx_id": "NANOSECOND_EXACT_TIE",
            "timestamp": "2026-06-01T12:00:00.123456789+00:00",
            "amount": "91.00",
            "status": "VALID"
        },
        {
            "tx_id": "NANOSECOND_EXACT_TIE",
            "timestamp": "2026-06-01T13:00:00.123456789+01:00",
            "amount": "92.00",
            "status": "FAILED"
        }
    ])

    # Later absolute instant despite an earlier wall-clock time.
    rows.extend([
        {
            "tx_id": "TZ_OFFSET_1",
            "timestamp": "2026-06-01T12:00:00+00:00",
            "amount": "10.00",
            "status": "VALID"
        },
        {
            "tx_id": "TZ_OFFSET_1",
            "timestamp": "2026-06-01T08:00:00-05:00",
            "amount": "20.00",
            "status": "FAILED"
        }
    ])

    # Earlier absolute instant despite a later wall-clock time.
    rows.extend([
        {
            "tx_id": "TZ_OFFSET_2",
            "timestamp": "2026-06-01T12:00:00+00:00",
            "amount": "30.00",
            "status": "VALID"
        },
        {
            "tx_id": "TZ_OFFSET_2",
            "timestamp": "2026-06-01T14:00:00+03:00",
            "amount": "40.00",
            "status": "FAILED"
        }
    ])

    # Three representations of the same instant.
    # The last CSV row must win.
    rows.extend([
        {
            "tx_id": "TZ_EXACT_TIE",
            "timestamp": "2026-06-01T12:00:00+00:00",
            "amount": "50.00",
            "status": "VALID"
        },
        {
            "tx_id": "TZ_EXACT_TIE",
            "timestamp": "2026-06-01T13:00:00+01:00",
            "amount": "60.00",
            "status": "FAILED"
        },
        {
            "tx_id": "TZ_EXACT_TIE",
            "timestamp": "2026-06-01T07:00:00-05:00",
            "amount": "70.00",
            "status": "PENDING"
        }
    ])

    # Additional randomized duplicate transactions.
    offsets = [-300, -240, 0, 60, 180, 330]

    for i in range(18):
        tx_id = f"DUP_{i}_{secrets.token_hex(3)}"

        base = (
            datetime(2026, 6, 1, 12, 0, tzinfo=timezone.utc)
            + timedelta(minutes=i * 7)
        )

        first = base + timedelta(
            minutes=rng.randint(-90, 90)
        )

        if i % 3 == 0:
            second = first
            third = first
        else:
            second = base + timedelta(
                minutes=rng.randint(-90, 90)
            )
            third = base + timedelta(
                minutes=rng.randint(-90, 90)
            )

        for instant in (first, second, third):
            offset = rng.choice(offsets)

            local = instant.astimezone(
                timezone(timedelta(minutes=offset))
            )

            rows.append({
                "tx_id": tx_id,
                "timestamp": local.isoformat(),
                "amount": random_amount(),
                "status": rng.choice([
                    "VALID", "FAILED", "PENDING"
                ])
            })

    return run_application(rows, use_cli=False)


checks = [
    ("CHECK 1 - CLI Argument Handling", "check1", check1),
    ("CHECK 2 - Status Accounting", "check2", check2),
    ("CHECK 3 - Timezone Deduplication", "check3", check3),
]

score = Decimal("0.00")

for label, key, function in checks:
    try:
        function()
        score += WEIGHTS[key]
        print(f"{label}: PASSED (+{WEIGHTS[key]})")

    except Exception as exc:
        print(f"{label}: FAILED - {exc}")

score = score.quantize(Decimal("0.01"))
write_reward(score)

print("---------------------------------------------")
print(f"DENSE REWARD: {score:.2f}/1.00")
print(f"Reward written to: {REWARD_FILE}")
PY
