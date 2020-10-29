#!/usr/bin/bash

#
# - Run a SUMO simulation
# - Convert the output XML to CSV
# - Upload the CSV to AWS/S3
# - Split the CSV in smaller files
# - Load the data from the CSV into AWS/RDS
#

usage() {
    echo "SUMO to AWS Data Pipeline"
    echo "Run a SUMO simulation, then
    - Generate a CSV with the result data
    - Upload the CSV to AWS/S3 (optional)
    - Load the CSV into a Database (optional)"
    echo ""
    echo "Usage: $0 [-h] REQUIRED [OPTIONAL]\n"
    echo "REQUIRED:"
    echo " SUMO_COMMAND,        The full sumo command to run, but the output file"
    echo " SUMO_OUTPUT_FILE,    Desired output file name, without extension"
    echo " SUMO_MODEL_PREFIX,   Prefix of the SUMO config file"
    echo " SUMO_TO_CSV,         Full path of the xml2csv.py script"
    echo ""
    echo "OPTIONAL:"
    echo " ENVR,                Full path to file with environment variables. If NULL"
    echo "                      it will try to source the file .env from the current directory."
    echo "                      It must be the FIRST of the optional arguments (or values may be overwritten)"
    echo " S3,                  1 to load the CSV to AWS/S3"
    echo " S3_BUCKET,           Name of the S3 bucket to load data onto. Required if S3=1"
    echo " AWS_KEY_ID,          Key ID for the AWS account. Required if S3=1"
    echo " AWS_SECRET_KEY,      Secret for the AWS account. Required if S3=1"
    echo " AWS_REGION,          Default region for the AWS account. Required if S3=1"
    echo " DB,                  1 to load the data from the CSV onto a PostgreSQL database"
    echo " DB_HOST,             URI for the database. Required if DB=1"
    echo " DB_USER,             Username to connect to the database. Required if DB=1"
    echo " DB_PASSWORD,         Password for the database user. Required if DB=1"
    echo " DATABASE,            Name of the database. Required if DB=1"
    echo " TABLE,               Name of the table to populate. The table will be created if"
    echo "                      it does not exist. Required if DB=1"
}

example() {
    echo "Example usage:"
    echo "./sumoToAws.sh \ "
    echo "  SUMO_COMMAND='-c /home/scenario/myModel.sumocfg -e 100 --fcd-output' \ "
    echo "  SUMO_MODEL_PREFIX=myModel \ "
    echo "  SUMO_TO_CSV=/home/sumo/tools/xml2csv.py \ "
    echo "  ENVR=/home/std_traffic/.env # it will contain the missing AWS_ variables"
    echo "  S3=1 \ "
    echo "  S3_BUCKET=standard-traffic-data \ "
    echo "  DB=1 \ "
    echo "  DB_HOST=localhost \ "
    echo "  DB_USER=postgres \ "
    echo "  DB_PASSWORD=traffic \ "
    echo "  DATABASE=sumodb \ "
    echo "  TABLE=my_model_end_100 \ "
}


if [[ "$1" == "-h" ]]
then
    usage
    example
    exit 0
fi

load_env (){
    if [ "$#" -lt 1 ]
    then
        echo "Trying current directory for .env"
        if . .env
        then
            echo "Loaded ENVR from current directory"
            ENVR='.env'
        fi
    else
        echo "Loading from $1"
        . $1
    fi
}


# try to load .env from current directory
# these may be overwritten by the command-line args
load_env

# parse (key, value) input arguments
# https://unix.stackexchange.com/a/353639
# overwrite the variables in the ENVR
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in

            SUMO_COMMAND)       SUMO_COMMAND=${VALUE} ;;
            SUMO_OUTPUT_FILE)   SUMO_OUTPUT_FILE=${VALUE} ;;
            SUMO_MODEL_PREFIX)  SUMO_MODEL_PREFIX=${VALUE} ;;
            SUMO_TO_CSV)        SUMO_TO_CSV=${VALUE} ;;
            ENVR)               load_env ${VALUE} ;;
            S3)                 S3=${VALUE} ;;
            S3_BUCKET)          S3_BUCKET=${VALUE} ;;
            AWS_KEY_ID)         AWS_KEY_ID=${VALUE} ;;
            AWS_SECRET_KEY)     AWS_SECRET_KEY=${VALUE} ;;
            AWS_REGION)         AWS_REGION=${VALUE} ;;
            DB)                 DB=${VALUE} ;;
            DB_USER)            DB_USER=${VALUE} ;;
            DB_PASSWORD)        DB_PASSWORD=${VALUE} ;;
            DB_HOST)            DB_HOST=${VALUE} ;;
            DB_PORT)            DB_PORT=${VALUE} ;;
            DATABASE)           DATABASE=${VALUE} ;;
            TABLE)              TABLE=${VALUE} ;;
            *)
    esac
done


if [ -z ${SUMO_COMMAND+x} ]
then
    echo "SUMO_COMMAND is unset"
    exit 1
fi

if [ -z ${SUMO_OUTPUT_FILE+x} ]
then
    echo "SUMO_OUTPUT_FILE is unset"
    exit 1
fi

if [ -z ${SUMO_MODEL_PREFIX+x} ]
then
    echo "SUMO_MODEL_PREFIX is unset"
    exit 1
fi

if [ -z ${SUMO_TO_CSV+x} ]
then
    echo "SUMO_TO_CSV is unset"
    exit 1
fi

if [[ "$S3" != "1" ]]
then
    echo "S3 will be set to 0 (false)"
    S3=0
else
    S3=1
fi

if [ -z ${AWS_KEY_ID+x} ] && [ "$S3" -eq 1 ]
then
    echo "AWS_KEY_ID is unset with S3=1"
    exit 1
fi

if [ "$S3" -eq 1 ] && [ -z ${AWS_SECRET_KEY+x} ]
then
    echo "AWS_SECRET_KEY is unset with S3=1"
    exit 1
fi

if [ "$S3" -eq 1 ] && [ -z ${S3_BUCKET+x} ]
then
    echo "S3_BUCKET is unset with S3=1"
    exit 1
fi

if [ "$S3" -eq 1 ] && [ -z ${AWS_REGION+1} ]
then
    echo "AWS_REGION is unset with S3=1"
    exit 1
fi

if [[ "$DB" != "1" ]]
then
    echo "DB will be set to 0 (false)"
    DB=0
else
    DB=1
fi

if [ "$DB" -eq 1 ] && [ -z ${DATABASE+x} ]
then
    echo "DATABASE is unset with DB=1"
    exit 1
fi

if [ "$DB" -eq 1 ] && [ -z ${DB_USER+x} ]
then
    echo "DB_USER is unset with DB=1"
    exit 1
fi

if [ "$DB" -eq 1 ] && [ -z ${DB_HOST+x} ]
then
    echo "DB_HOST is unset with DB=1"
    exit 1
fi

if [ "$DB" -eq 1 ] && [ -z ${DB_PASSWORD+x} ]
then
    echo "DB_PASSWORD is unset with DB=1"
    exit 1
fi

if [ -z ${DB_PORT+x} ]
then
    echo "Setting default DB_PORT=5432"
    DB_PORT=5432
fi

if [ "$DB" -eq 1 ] && [ -z ${TABLE+x} ]
then
    echo "TABLE is unset with DB=1"
    exit 1
fi

if [ "$DB" -eq 1 ] || [ "$S3" -eq 1 ]
then
    # verify that python package is installed
    if python -c "import std_traffic"
        then echo "Found python module"
        else
            echo "Cannot find python package std_traffic. 
                 Are you running this into a virtualenv?"
            exit 1
    fi
fi


# run sumo with the given args string
sumo $SUMO_COMMAND /tmp/$SUMO_OUTPUT_FILE.xml

# convert the output to CSV
python ${SUMO_TO_CSV} /tmp/${SUMO_MODEL_PREFIX}.${SUMO_OUTPUT_FILE}.xml


if [ $S3 -eq 1 ]
# upload the CSV to AWS/S3
then
    export S3_BUCKET=${S3_BUCKET}
    export AWS_KEY_ID=${AWS_KEY_ID}
    export AWS_SECRET_KEY=${AWS_SECRET_KEY}
    export AWS_REGION=${AWS_REGION}
    # this requires the std_traffic package installed
    # pip install git@..
    # or from local pip install -e ./
    upload_file_s3.py \
        /tmp/${SUMO_MODEL_PREFIX}.${SUMO_OUTPUT_FILE}.csv \
        ${SUMO_OUTPUT_FILE}.csv \
        ${S3_BUCKET} \
        true
fi

# load data into AWS/RDS
if [ $DB -eq 1 ]
then
    export DB_HOST=${DB_HOST}
    export DB_PASSWORD=${DB_PASSWORD}
    export DB_PORT=${DB_PORT}
    export DB_USER=${DB_USER}
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
    find "$(pwd -P)" /tmp -maxdepth 1 -name '*.csv.0*' -exec \
        load_csv_psql.py {} ${DATABASE} ${TABLE} \;
fi