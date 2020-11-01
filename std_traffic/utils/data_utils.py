"""Utility functions to process data"""

from os import environ
import logging

import psycopg2
import psycopg2.extras
from psycopg2 import sql
from psycopg2.extensions import AsIs
from psycopg2.extensions import connection

import pandas as pd
import numpy as np


log = logging.getLogger(__name__)


def get_db(
        database: str,
        user: str = None,
        password: str = None,
        host: str = None,
        port: int = None,
) -> connection:
    """Create a connection to a database.
    The default connection parameters are taken from ENV
    """

    if not user:
        user = environ['DB_USER']
    if not password:
        password = environ['DB_PASSWORD']
    if not host:
        host = environ['DB_HOST']
    if not port:
        port = 5432
    return psycopg2.connect(
        host=host,
        database=database,
        user=user,
        password=password,
        port=port,
        cursor_factory=psycopg2.extras.DictCursor)


def get_columns(csv_file: str, delim: str = ';') -> dict:
    """Extract the column names and types from a CSV file.
    The default choice for the delimiter (;) is related to SUMO defaults.

    :param csv_file: (str) Path to the CSV.
    :param delim: (str) Delimiter character used in the CSV (default ;).
    :return: (dict) Map column_name -> column_type. Types are Numpy's.
    """

    # use pandas features
    # - Read first 1000 row, get columns names, infer types
    #   by avoiding NA columns
    # - For each column type missing
    #   keep reading only that column in chunks until a type is found
    #   or EOF
    initial = 1000
    dataf = pd.read_csv(csv_file, sep=delim, nrows=initial)
    all_names = set(dataf.columns)
    df_ = dataf[dataf.columns[~dataf.isnull().all()]]
    result = dict(df_.dtypes)

    default = 'O'
    still_missing = {key for key in all_names if key not in result}
    for current_col in still_missing:
        df_chunk = pd.read_csv(csv_file, header=0,
                               skiprows=range(1, initial), sep=delim,
                               chunksize=5000, usecols=[current_col])
        for chunk in df_chunk:
            chunk_ = chunk.dropna()
            if chunk_.shape[0] > 0:
                break
        if chunk_.shape[0] > 0:
            result[current_col] = chunk_[current_col].dtype
        else:
            result[current_col] = default
    """
    # - read the first 1000 to get all columns names.
    #   Get not NaN at the same time.
    # - keep reading in chunks until all column types are inferred,
    #   or EOF is reached
    total_len = len(all_names)
    df_chunk = pd.read_csv(csv_file, skiprows=initial,
                           sep=delim, chunksize=100)
    for chunk in df_chunk:
        if len(result) == total_len:
            break
        df_ = chunk[chunk.columns[~chunk.isnull().all()]]
        dtypes_ = dict(df_.dtypes)
        for key, val in dtypes_.items():
            if key not in result:
                result[key] = val
    # if some columns are still unassigned
    # then they are entirely null
    default = 'O'
    for key in all_names:
        if key not in result:
            result[key] = default
    """
    return result


def create_table_from_csv(
        conn: connection,
        table: str,
        csv_file: str,
        delim: str = ';'
) -> bool:
    """Creates a table in PostgreSQL from a CSV header.
    If the table exists, it does nothing.

    :param conn: Psycopg2 connection to DB.
    :param table: (str) Name of the new table.
    :param csv_file: (str) Path of the CSV file.
    :param delim: (str) Delimiter used in the CSV.
    :param nrows: (int) Number of rows to infer types.
    :return: (bool) True if a new table was created.
    """

    query0 = """
        select exists (
            select * from information_schema.tables
            where table_name = %s);
    """
    query1 = sql.SQL('create table if not exists {} ();')
    query2 = sql.SQL('alter table {} add column {} %s;')
    with conn.cursor() as cur:
        cur.execute(query0, (table,))
        exists = cur.fetchone()[0]
    if exists:
        return False

    columns = get_columns(csv_file, delim=delim)
    # because table and column names are variable
    # create first an empty table, then add columns
    # it may raise
    with conn.cursor() as cur:
        cur.execute(query1.format(sql.Identifier(table)))
        for key, val in columns.items():
            col_name = key
            col_type = map_numpy_psql(val)
            cur.execute(query2.format(
                sql.Identifier(table),
                sql.Identifier(col_name)),
                (AsIs(col_type),)
            )
    conn.commit()
    return True


def map_numpy_psql(dtype_: np.dtype) -> str:
    """map the a Numpy type to PostgreSQL type"""

    mapper = {
        'int64': 'bigint',
        'float64': 'real',
        'float32': 'float4',
        'int32': 'int',
        'O': 'text'
    }
    try:
        return mapper[str(dtype_)]
    except KeyError:
        # return psql string as default
        return 'text'


def load_table_from_csv(
        conn: connection,
        table: str,
        filep: str,
        delim: str = ';',
        headers: bool = True
):
    """Load records from a CSV file onto a table
    in PostgreSQL.

    Assume the CSV and the DB have coherent format. Raises
    exception otherwise.

    :param conn: (connection) Database connection (psycopg2)
    :param table: (str) Table to be populated
    :param filep: (str) CSV file path
    :param delim: (str) Delimiter used in the CSV. Default to ';'
    :param headers: (bool) True (default) is the CSV contains headers
    """

    freader = open(filep, 'rb')
    if headers:
        # psycopg2 does not handle headers
        next(freader)
    with conn.cursor() as cur:
        cur.copy_from(
            freader,
            table=table,
            sep=delim,
            null='')
    conn.commit()
