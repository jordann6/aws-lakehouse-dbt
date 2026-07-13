#!/usr/bin/env python3
"""Generate the raw_orders dbt seed (deterministic, seed=42).

Kept small (5k rows) because dbt seeds are committed to the repo and loaded
row-wise; the marts still demonstrate the full bronze -> silver -> gold flow.
"""
import csv
import random
from datetime import date, timedelta

ROWS = 5_000
CATEGORIES = ["electronics", "apparel", "home", "grocery", "toys", "books"]
COUNTRIES = ["US", "CA", "GB", "DE", "AU"]
OUT = "dbt/seeds/raw_orders.csv"

random.seed(42)
start = date(2025, 1, 1)

with open(OUT, "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["order_id", "customer_id", "order_date", "product_category",
                "quantity", "unit_price", "country"])
    for i in range(1, ROWS + 1):
        w.writerow([
            i,
            random.randint(1, 2000),
            (start + timedelta(days=random.randint(0, 89))).isoformat(),
            random.choice(CATEGORIES),
            random.randint(1, 5),
            round(random.uniform(4.99, 899.99), 2),
            random.choice(COUNTRIES),
        ])
print(f"wrote {ROWS} rows to {OUT}")
