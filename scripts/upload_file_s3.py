"""Runnable script to upload a file to AWS/S3"""

import argparse
import logging

from std_traffic.utils import aws_utils


logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s [%(module)s] - %(message)s',
    handlers=[logging.StreamHandler()])

log = logging.getLogger(__name__)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'filep',
        help='Full file path to upload')
    parser.add_argument(
        'key',
        help='File name in AWS/S3')
    parser.add_argument(
        'bucket',
        help='S3 bucket name')
    parser.add_argument(
        'large',
        type=bool,
        help='Use True to enfore multipart upload')
    args = parser.parse_args()
    success = aws_utils.upload_file(
        args.bucket,
        args.filep,
        args.key,
        large=args.large)
    if success:
        log.debug('Upload successful')
    else:
        log.warning('Error upload %s', args.filep)
