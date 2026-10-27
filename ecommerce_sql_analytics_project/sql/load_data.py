from pathlib import Path
import sqlite3
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "ecommerce_analytics.db"
DATA = ROOT / "data"
SCHEMA = ROOT / "sql" / "01_schema.sql"

if DB.exists():
    DB.unlink()
con = sqlite3.connect(DB)
try:
    con.executescript(SCHEMA.read_text(encoding="utf-8"))
    for table in ["customers", "products", "orders", "order_items"]:
        pd.read_csv(DATA / f"{table}.csv").to_sql(table, con, if_exists="append", index=False)
    con.commit()
    print(f"Created {DB.name}")
    for table in ["customers", "products", "orders", "order_items"]:
        print(f"{table}: {con.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]:,} rows")
finally:
    con.close()
