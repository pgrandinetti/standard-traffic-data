# Data Pipelines

This directory contains data pipelines used to generate, collect, share, and publish data. In general they are implemented so to have a runnable script (bash, Python, Go, ...) that uses other software or API (SUMO, to name one) and custom functions developed in `std_traffic`.

Next follows a description of the data pipelines currently implemented.

## SUMO to AWS

Usage: `/bin/bash sumoToAWS.sh -h`

This pipeline executes the following tasks:

  - It runs a SUMO simulation, in local. This will output a XML file.
  - It converts the XML into a CSV.
  - It uploads the CSV on to a AWS/S3 bucket.
  - It loads data from the CSV into a PostgreSQL database.

The pipeline needs to be started with several command line arguments. Again, see example usage in `/bin/bash sumoToAWS.sh -h`.

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
