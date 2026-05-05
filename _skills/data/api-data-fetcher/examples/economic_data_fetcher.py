"""Economic data fetcher examples for FRED and World Bank.

Setup:
    pip install fredapi wbdata pandas
    export FRED_API_KEY="your_key_here"
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Dict, List, Optional

import pandas as pd


def fetch_fred_series(
    series_ids: List[str],
    start_date: str = "2000-01-01",
    end_date: Optional[str] = None,
    api_key: Optional[str] = None,
) -> pd.DataFrame:
    """Fetch time series data from FRED."""
    try:
        from fredapi import Fred
    except ImportError as exc:
        raise ImportError("Install fredapi: pip install fredapi") from exc

    api_key = api_key or os.environ.get("FRED_API_KEY")
    if not api_key:
        raise ValueError(
            "FRED API key required. Set FRED_API_KEY or pass api_key. "
            "Get a key at https://fred.stlouisfed.org/docs/api/api_key.html"
        )

    fred = Fred(api_key=api_key)
    end_date = end_date or datetime.now().strftime("%Y-%m-%d")
    data = {}

    for series_id in series_ids:
        try:
            data[series_id] = fred.get_series(
                series_id,
                observation_start=start_date,
                observation_end=end_date,
            )
            print(f"OK: downloaded {series_id}")
        except Exception as exc:  # API libraries raise provider-specific exceptions.
            print(f"FAILED: {series_id}: {exc}")

    df = pd.DataFrame(data)
    df.index.name = "date"
    return df


FRED_SERIES = {
    "GDP": "Gross Domestic Product",
    "GDPC1": "Real GDP",
    "GDPPOT": "Real Potential GDP",
    "UNRATE": "Unemployment Rate",
    "PAYEMS": "Total Nonfarm Payrolls",
    "CIVPART": "Labor Force Participation Rate",
    "CPIAUCSL": "Consumer Price Index",
    "PCEPI": "PCE Price Index",
    "CPILFESL": "Core CPI",
    "FEDFUNDS": "Federal Funds Rate",
    "DGS10": "10-Year Treasury Rate",
    "T10Y2Y": "10Y-2Y Treasury Spread",
    "M2SL": "M2 Money Stock",
    "TOTRESNS": "Total Reserves",
}


def fetch_world_bank_data(
    indicators: Dict[str, str],
    countries: List[str] | None = None,
    start_year: int = 2000,
    end_year: Optional[int] = None,
) -> pd.DataFrame:
    """Fetch indicator data from World Bank as a country-year panel."""
    try:
        import wbdata
    except ImportError as exc:
        raise ImportError("Install wbdata: pip install wbdata") from exc

    countries = countries or ["USA", "GBR", "DEU", "FRA", "JPN"]
    end_year = end_year or datetime.now().year
    all_data = []

    for indicator_code, indicator_name in indicators.items():
        try:
            data = wbdata.get_dataframe({indicator_code: indicator_name}, country=countries)
            all_data.append(data.reset_index())
            print(f"OK: downloaded {indicator_name}")
        except Exception as exc:  # API libraries raise provider-specific exceptions.
            print(f"FAILED: {indicator_name}: {exc}")

    if not all_data:
        return pd.DataFrame()

    df = all_data[0]
    for other_df in all_data[1:]:
        df = df.merge(other_df, on=["country", "date"], how="outer")

    df["year"] = pd.to_datetime(df["date"]).dt.year
    return df[(df["year"] >= start_year) & (df["year"] <= end_year)]


WORLD_BANK_INDICATORS = {
    "NY.GDP.PCAP.CD": "GDP per capita (current US$)",
    "NY.GDP.PCAP.KD.ZG": "GDP per capita growth (%)",
    "NY.GDP.MKTP.KD.ZG": "GDP growth (%)",
    "SP.POP.TOTL": "Population, total",
    "SP.URB.TOTL.IN.ZS": "Urban population (%)",
    "NE.TRD.GNFS.ZS": "Trade (% of GDP)",
    "BX.KLT.DINV.WD.GD.ZS": "FDI, net inflows (% of GDP)",
    "SE.XPD.TOTL.GD.ZS": "Education expenditure (% of GDP)",
    "SH.XPD.CHEX.GD.ZS": "Health expenditure (% of GDP)",
    "SI.POV.GINI": "Gini index",
    "SI.POV.DDAY": "Poverty headcount ratio ($1.90/day)",
}


if __name__ == "__main__":
    us_macro = fetch_fred_series(
        series_ids=["GDP", "UNRATE", "CPIAUCSL", "FEDFUNDS"],
        start_date="2010-01-01",
    )
    us_macro.to_csv("data/us_macro_fred.csv")

    indicators = {
        "NY.GDP.PCAP.CD": "gdp_per_capita",
        "SP.POP.TOTL": "population",
        "NY.GDP.MKTP.KD.ZG": "gdp_growth",
    }
    cross_country = fetch_world_bank_data(
        indicators=indicators,
        countries=["USA", "GBR", "DEU", "FRA", "JPN", "CHN", "IND", "BRA"],
        start_year=2000,
    )
    cross_country.to_csv("data/cross_country_wb.csv", index=False)
