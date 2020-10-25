"""Utility functions to use AWS services"""

import logging
from os import environ

import boto3
from botocore.exceptions import ClientError
from boto3.s3.transfer import TransferConfig


def _init_client(client_name: str) -> boto3.client:
    return boto3.client(
        client_name,
        aws_access_key_id=environ['AWS_KEY_ID'],
        aws_secret_access_key=environ['AWS_SECRET_KEY'],
        region_name=environ['AWS_REGION'])


def get_s3_client() -> boto3.client:
    """Create a connection client to S3."""

    return _init_client('s3')


def upload_file(
        bucket_name: str,
        file_path: str,
        aws_name: str = None,
        large: bool = False,
        thrsh: int = None
) -> bool:
    """Upload a large file to aws/s3 using multipart upload.

    :param bucket_name: (str) S3 bucket to upload to.
    :param file_path: (str) The file to be uploaded.
    :param aws_name: (str) The name to save the file with.
    :param large: (bool) If true then multipart upload will be used.
    :param thrsh: (int) Threshold (in bytes) for each part to upload.
    :return: (bool) True if file was uploaded, else False
    """

    def _upload_file():
        # this function uses the relative scoping features
        client = get_s3_client()
        if large:
            config = TransferConfig(
                multipart_threshold=thrsh_,
                max_concurrency=10,
                multipart_chunksize=thrsh_,
                use_threads=True)
            client.upload_file(
                file_path,
                bucket_name,
                aws_name,
                Config=config)
        else:
            client.upload_file(
                file_path,
                bucket_name,
                aws_name)

    if not aws_name:
        aws_name = file_path
    if not thrsh:
        # default value
        thrsh_ = 1024 ** 3
    else:
        thrsh_ = thrsh
    try:
        _upload_file()
    except ClientError as exc:
        logging.error(exc)
        return False
    else:
        return True
