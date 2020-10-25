#!/usr/bin/bash

#
# - Run a SUMO simulation
# - Convert the output XML to CSV
# - Upload the CSV to AWS/S3
# - Split the CSV in smaller files
# - Load the data from the CSV into AWS/RDS
#
#
# SUMO_COMMAND='-c /home/MoSTScenario/scenario/most.sumocfg -e 15000 --fcd-output'
# SUMO_OUTPUT_FILE='saveout' <-- do not use .xml
# SUMO_MODEL_PREFIX='most'
# SUMO_TO_CSV='/home/sumo/tools/xml2csv.py'
# S3=1
# DB=1
# DATABASE=sumodb
# TABLE=test_csv
# ENVR=/home/.env


# parse (key, value) input arguments
# https://unix.stackexchange.com/a/353639
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            SUMO_COMMAND)       SUMO_COMMAND=${VALUE} ;;
            SUMO_OUTPUT_FILE)   SUMO_OUTPUT_FILE=${VALUE} ;;
            SUMO_MODEL_PREFIX)  SUMO_MODEL_PREFIX=${VALUE} ;;
            SUMO_TO_CSV)        SUMO_TO_CSV=${VALUE} ;;
            S3)                 S3=${VALUE} ;;
            DB)                 DB=${VALUE} ;;
            DATABASE)           DATABASE=${VALUE} ;;
            TABLE)              TABLE=${VALUE} ;;
            ENVR)               ENVR=${VALUE} ;; 
            *)
    esac
done

# run sumo with the given args string
sumo $SUMO_COMMAND /tmp/$SUMO_OUTPUT_FILE.xml

# convert the output to CSV
python ${SUMO_TO_CSV} /tmp/${SUMO_MODEL_PREFIX}.${SUMO_OUTPUT_FILE}.xml

if [ $S3 -eq 1 ]
# upload the CSV to AWS/S3
then
    # this required the std_traffic package installed
    # pip install git@..
    # or from local pip install -e ./
    . ${ENVR} && upload_file_s3.py \
        /tmp/${SUMO_MODEL_PREFIX}.${SUMO_OUTPUT_FILE}.csv \
        /tmp/${SUMO_OUTPUT_FILE}.csv \
        standard-traffic-data \
        true
fi

# load data into AWS/RDS
if [ $DB -eq 1 ]
then
    # split CSV into smaller files
    # put 1,000,000 rows in each file (keep the header in every file)
    # https://stackoverflow.com/a/51421525
    # output files will be named [..].csv.00001
    awk -v m=1000000 '
        (NR==1){h=$0;next}
        (NR%m==2) { close(f); f=sprintf("%s.%0.5d",FILENAME,++c); print h > f }
        {print > f}' /tmp/${SUMO_MODEL_PREFIX}.${SUMO_OUTPUT_FILE}.csv
    
    # find all files generated by awk
    # and load them in PostgreSQL
    . ${ENVR} && find "$(pwd -P)" /tmp -maxdepth 1 -name '*.csv.0*' -exec \
        load_csv_psql.py {} ${DATABASE} ${TABLE} \;
fi
