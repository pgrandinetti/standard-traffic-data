"""Installer"""

import setuptools


with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="Standard-Traffic-Data",
    version="0.0.1",
    author="Pietro Grandinetti",
    description="Methods and Tools to standardize road traffic datasets.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/pgrandinetti/standard-traffic-data",
    packages=setuptools.find_packages(),
    scripts=[
        'scripts/upload_file_s3.py',
        'scripts/load_csv_psql.py',
    ],
    python_requires='>=3.6',
)
