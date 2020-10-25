""""Runnable script to load a CSV into a
PostgreSQL table"""

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
        '--delim',
        help='Delimiter used in CSV',
        default=';')
    parser.add_argument(
        '--host',
        help='Database host',
        default=environ['DB_HOST'])
    parser.add_argument(
        '--user',
        help='Database username',
        default=environ['DB_USER'])
    parser.add_argument(
        '--password',
        help='Database user password',
        default=environ['DB_PASSWORD'])
    parser.add_argument(
        '--port',
        help='Database connection port',
        default=5432)

    args = parser.parse_args()
    with get_db(
            args.database,
            args.user,
            args.password,
            args.host,
            args.port) as connection:
        created = create_table_from_csv(
            connection,
            args.table,
            args.filep,
            delim=args.delim)
        if created:
            log.debug('New table created')
        else:
            log.debug('Table existed')
        load_table_from_csv(
            connection,
            args.table,
            args.filep,
            delim=args.delim,
            headers=args.headers)
