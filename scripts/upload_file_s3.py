"""Runnable script to upload a file to AWS/S3"""

import time
import argparse
import logging
from os import environ

from std_traffic.utils import aws_utils


logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s [%(module)s] - %(message)s',
    handlers=[logging.StreamHandler()])

log = logging.getLogger(__name__)

# make AWS logging silent
log_boto = logging.getLogger('botocore')
log_boto.setLevel(logging.ERROR)
log_s3 = logging.getLogger('s3transfer')
log_s3.setLevel(logging.ERROR)


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
        '--large',
        type=bool,
        default=True,
        help='Use True to enforce multipart upload')
    parser.add_argument(
        '--aws-key-id',
        help='AWS KEY ID')
    parser.add_argument(
        '--aws-secret-key',
        help='AWS SECRET ACCESS KEY')
    parser.add_argument(
        '--aws-region',
        help='Default AWS region')
    args = parser.parse_args()

    if not args.aws_region:
        args.aws_region = environ['AWS_REGION']
    if not args.aws_secret_key:
        args.aws_secret_key = environ['AWS_SECRET_KEY']
    if not args.aws_key_id:
        args.aws_key_id = environ['AWS_KEY_ID']

    log.debug('Uploading file %s', args.filep)
    t_0 = time.time()
    success = aws_utils.upload_file(
        args.bucket,
        args.filep,
        args.key,
        large=args.large,
        AWS_KEY_ID=args.aws_key_id,
        AWS_SECRET_KEY=args.aws_secret_key,
        AWS_REGION=args.aws_region)
    delta = int(time.time() - t_0)
    if success:
        log.debug('Upload successful: %s seconds', delta)
    else:
        log.warning('Error upload %s', args.filep)
