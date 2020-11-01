""""Runnable script to load a CSV into a
PostgreSQL table"""

import time
import argparse
from os import environ
import logging

from std_traffic.utils.data_utils import (
    get_db,
    create_table_from_csv,
    load_table_from_csv
)


logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s [%(module)s] - %(message)s',
    handlers=[logging.StreamHandler()])

log = logging.getLogger(__name__)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'filep',
        help='CSV file path')
    parser.add_argument(
        'database',
        help='Database name')
    parser.add_argument(
        'table',
        help='Table name')
    parser.add_argument(
        '--headers',
        help='true if the CSV contains the headers',
        default=True)
    parser.add_argument(
        '--columns',
        help='list of column names',
        nargs='*',
        type=str,
        default=None)
    parser.add_argument(
        '--delim',
        help='Delimiter used in CSV',
        default=';')
    parser.add_argument(
        '--host',
        help='Database host')
    parser.add_argument(
        '--user',
        help='Database username')
    parser.add_argument(
        '--password',
        help='Database user password')
    parser.add_argument(
        '--port',
        help='Database connection port',
        default=5432)
    args = parser.parse_args()

    if not args.host:
        args.host = environ['DB_HOST']
    if not args.user:
        args.user = environ['DB_USER']
    if not args.password:
        args.password = environ['DB_PASSWORD']

    with get_db(
            args.database,
            args.user,
            args.password,
            args.host,
            args.port) as connection:
        # functions used below can raise
        # if so, connection will close from context
        # and rollback automatically
        created = create_table_from_csv(
            connection,
            args.table,
            args.filep,
            delim=args.delim)
        if created:
            log.debug('New table created')
        else:
            log.debug('Table existed')
        log.debug('Loading file %s in table %s',
                  args.filep, args.table)
        t_0 = time.time()
        load_table_from_csv(
            connection,
            args.table,
            args.filep,
            delim=args.delim,
            headers=args.headers,
            columns=args.columns)
        delta = int(time.time() - t_0)
        log.debug('File %s loaded in %s seconds',
                  args.filep, delta)
