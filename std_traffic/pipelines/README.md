# Data Pipelines

This directory contains data pipelines used to generate, collect, share, and publish data. In general they are implemented so to have a runnable script (bash, Python, Go, ...) that uses other software or API (SUMO, to name one) and custom functions developed in `std_traffic`.

Next follows a description of the data pipelines currently implemented.

## SUMO to AWS

Usage: `/bin/bash sumoToAws.sh -h`

This pipeline executes the following tasks:

  - It runs a SUMO simulation, in local. This will output a XML file.
  - It converts the XML into a CSV.
  - It uploads the CSV on to a AWS/S3 bucket.
  - It loads data from the CSV into a PostgreSQL database.

The pipeline needs to be started with several command line arguments. Again, see example usage in `/bin/bash sumoToAws.sh -h`.

Here's an example:

```
/bin/bash std_traffic/pipelines/sumoToAws.sh \
SUMO_COMMAND="-c /home/test/test.sumocfg -e 14600 --fcd-output" \  # <-- The command you'd run in SUMO
SUMO_MODEL_PREFIX=test \                                           # <-- The name of your model, used as file prefix by SUMO
SUMO_TO_CSV="/home/tools/xml2csv.py" \                             # <-- Path to the xml2csv.py tool.
SUMO_OUTPUT_FILE=sim_2_1 \                                         # <-- Name of the output files (XML and CSV)
ENVR=.env \                                                        # <-- Path of a file with environment variables (for AWS and DB connection)
S3=1 \                                                             # <-- If 1, will upload to AWS/S3
S3_BUCKET=standard-traffic-data \                                  # <-- Name of the S3 bucket to upload onto
DB=1 \                                                             # <-- If 1, will load into a PostgreSQL database
DATABASE=sumodb \                                                  # <-- Name of the database to use
TABLE=test_indexes_2 \                                             # <-- Name of the table. Will be created if it doesn't exist
CLEANUP=1                                                          # <-- If 1, will remove files generated
```

### Dockerized pipeline

We provide a Dockerfile to reproduce the entire SUMO to AWS pipeline that enables you to run it off-the-shelf, with no software installed other than Docker. This is meant to provide 100% reproducibilty of the experiments, datasets and, hence, reproducible data science.

Copy the file from `/std_traffic/pipelines/Dockerfile.sumoToAws`. Then prepare a file `docker.env` to set up your test. This file can be anywhere in your local system and should be similar to the following:

```
# Boto secrets
AWS_KEY_ID=*****
AWS_SECRET_KEY=*****
AWS_REGION=****

# RDS
DB_USER=****
DB_PASSWORD=****
DB_PORT=5432
DB_HOST=****
DB_NAME=****

# Docker run options
SUMO_COMMAND=most.sumocfg -e 46800 --step-length 1 --device.fcd.period 5 --fcd-output
SUMO_MODEL_PREFIX=most
SUMO_OUTPUT_FILE=most_0400_1300_1_5
S3=1
S3_BUCKET=****
DB=1
TABLE=most_0400_1300_1_5
DATABASE=sumodb
CLEANUP=1
```

The meaning of these variables is the same as in the pipeline.

Now you only need to execute the following two lines:

```
docker build -t sumotest -f Dockerfile.sumoToAws .
docker run --env-file /path/to/docker.env sumotest
```

**No remote upload**. If you don't mean to upload the dataset anywhere, and just want to use it for local analysis, set `CLEANUP`, `S3` and `DB` to `0` and when the execution is finished you can use `docker cp` to transfer the CSV from inside the container to your local system. The command, in general, would be

```
docker cp containerId:/tmp/$SUMO_MODEL_PREFIX.$SUMO_OUTPUT_FILE.csv /path/to/local/filename.csv
```

for instance: `docker cp c6000a605045:/tmp/most.most_0400_1300_1_5.csv /home/test_123.csv`. You can find the `containerId` with `docker ps -a`. Check the documentation for [docker cp](https://docs.docker.com/engine/reference/commandline/cp/) for more details.

**Changing the SUMO scenario**. You may of course want to use a model different from MoST. The Dockerfile allows you to do so by changing two `ARG` variables:

  - `MODEL_LOC` This must be a git repository with all the files SUMO needs to run the experiment. We encourage you to keep this repository public.
  - `MODEL_DIR` The name of the directory, inside the git repository, where the `.sumocfg` is located.

The Dockerfile will clone the git repository specified during the `docker build` and run the scenario from therein.
