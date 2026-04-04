#!/usr/bin/env python3
"""Export Garmin SQLite databases to Parquet files, one file per table."""

import argparse
import os
import sqlite3
import sys
from pathlib import Path

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq


def list_tables(conn: sqlite3.Connection) -> list[str]:
    cur = conn.execute(
        "SELECT name FROM sqlite_master "
        "WHERE type='table' AND name NOT LIKE '\\_%' ESCAPE '\\' "
        "ORDER BY name"
    )
    return [row[0] for row in cur.fetchall()]


def export_table(
    conn: sqlite3.Connection, table: str, out_path: Path, chunksize: int
) -> int:
    writer: pq.ParquetWriter | None = None
    rows = 0
    try:
        for chunk in pd.read_sql_query(
            f'SELECT * FROM "{table}"', conn, chunksize=chunksize
        ):
            table_arrow = pa.Table.from_pandas(chunk, preserve_index=False)
            if writer is None:
                writer = pq.ParquetWriter(
                    out_path, table_arrow.schema, compression="zstd"
                )
            else:
                # Align schema with writer's (handles chunks where a column
                # might be entirely null and inferred differently).
                table_arrow = table_arrow.cast(writer.schema)
            writer.write_table(table_arrow)
            rows += len(chunk)
        if writer is None:
            # Empty table: write a zero-row parquet with inferred schema.
            df = pd.read_sql_query(f'SELECT * FROM "{table}" LIMIT 0', conn)
            table_arrow = pa.Table.from_pandas(df, preserve_index=False)
            pq.write_table(table_arrow, out_path, compression="zstd")
    finally:
        if writer is not None:
            writer.close()
    return rows


def export_db(db_path: Path, out_dir: Path, chunksize: int) -> None:
    stem = db_path.stem
    dest = out_dir / stem
    dest.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    try:
        for table in list_tables(conn):
            out_path = dest / f"{table}.parquet"
            tmp_path = out_path.with_suffix(".parquet.tmp")
            rows = export_table(conn, table, tmp_path, chunksize)
            os.replace(tmp_path, out_path)
            print(f"  {stem}/{table}: {rows} rows -> {out_path}")
    finally:
        conn.close()


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--db-dir",
        type=Path,
        required=True,
        help="Directory containing *.db files",
    )
    p.add_argument(
        "--out-dir",
        type=Path,
        required=True,
        help="Output directory for Parquet files",
    )
    p.add_argument(
        "--chunksize",
        type=int,
        default=100_000,
        help="Rows per chunk when reading SQL tables",
    )
    args = p.parse_args()

    dbs = sorted(args.db_dir.glob("*.db"))
    if not dbs:
        print(f"No *.db files found in {args.db_dir}", file=sys.stderr)
        return 1

    args.out_dir.mkdir(parents=True, exist_ok=True)
    for db in dbs:
        print(f"Exporting {db.name}")
        export_db(db, args.out_dir, args.chunksize)
    return 0


if __name__ == "__main__":
    sys.exit(main())
