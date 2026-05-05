"""run_all.py

Master orchestration script for ProjectABC's data pipeline.
Python equivalent of a DIME master do-file.

Run from the project root:

    uv run python pipelines/run_all.py

Or:

    make data
"""

from __future__ import annotations

import os
from datetime import date
from pathlib import Path

from dotenv import load_dotenv

# Local fetchers (one module per source)
from fetch_fred       import fetch_fred
from fetch_worldbank  import fetch_worldbank
from build_panel      import build_macro_panel

# 1. Load secrets from .env (never commit .env) ----------------
load_dotenv()
assert os.getenv("FRED_API_KEY"), "Set FRED_API_KEY in .env (see .env.example)"

# 2. Dynamic absolute paths ------------------------------------
PROJECT      = Path(__file__).resolve().parents[1]
DATA_RAW     = PROJECT / "data" / "raw"
DATA_INT     = PROJECT / "data" / "intermediate"
DATA_FINAL   = PROJECT / "data" / "processed"
DATA_CACHE   = PROJECT / "data" / "cache"
DOCS         = PROJECT / "docs"
for p in (DATA_RAW, DATA_INT, DATA_FINAL, DATA_CACHE, DOCS):
    p.mkdir(parents = True, exist_ok = True)

VINTAGE = date.today().isoformat()
print(f"Pipeline vintage: {VINTAGE}")

# 3. Fetch each source (each writes immutable raw files) -------
fetch_fred(
    out_dir = DATA_RAW / "fred",
    docs    = DOCS,
    vintage = VINTAGE,
)
fetch_worldbank(
    out_dir = DATA_RAW / "worldbank",
    docs    = DOCS,
    vintage = VINTAGE,
)

# 4. Build the analysis-ready panel ----------------------------
build_macro_panel(
    raw_dir   = DATA_RAW,
    int_dir   = DATA_INT,
    final_dir = DATA_FINAL,
    docs_dir  = DOCS,
    vintage   = VINTAGE,
)

print(f"Pipeline complete. Outputs in {DATA_FINAL}")
