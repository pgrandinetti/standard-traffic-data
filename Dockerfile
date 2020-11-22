FROM ubuntu:20.04

# MODEL_LOC: the remote git repository that will be fetched
# and used as default SUMO model.
# The default value is the MoST model
# https://ieeexplore.ieee.org/document/8275627
ARG MODEL_LOC=https://github.com/pgrandinetti/MoSTScenario

# MODEL_DIR: the directory, inside $MODEL_LOC
# where the sumo cfg file will be searched.
# The default value is relative to the MoST package.
ARG MODEL_DIR=scenario

# SUMO_COMMAND: the command to be given to the `sumo' executable
# If you'd run `sumo -c /home/scenario/mymodel.sumocfg -e 1000 --fcd-output'
# then set `SUMO_COMMAND=mymodel.sumocfg -e 1000 --fcd-output'
# General value: `SUMO_COMMAND=<model.sumofcg> [options]'
# The default value is a 30 min run of MoST (4:00am to 4:30am)
# with 1 second simulation sampling time
# and 5 seconds output sampling time
ENV SUMO_COMMAND="most.sumocfg -e 16200 --step-length 1 --device.fcd.period 5 --fcd-output"

# SUMO_MODEL_PREFIX: the prefix you chose and used by SUMO
# to name the output files. Must be coherent with `SUMO_COMMAND'
ENV SUMO_MODEL_PREFIX=most

# SUMO_OUTPUT_FILE: the name you want to give the output file.
# Extensions will be added by default at .xml
ENV SUMO_OUTPUT_FILE=most_0400_0430_1_5

# S3, DB: consistent with the same variables in the pipeline.
# Set to 1 to upload the CSV file to AWS/S3, or to load data into a
# PostgreSQL database.
ENV S3=0
ENV DB=0

# CLEANUP: consistent with the same variable in the pipeline.
# Set to 1 if you want to delete the files generated during the run.
ENV CLEANUP=0

# secret credentials for AWS/S3 and for the database.
# These must be set at runtime.
ENV AWS_KEY_ID=***
ENV AWS_SECRET_KEY=***
ENV AWS_REGION=***
ENV S3_BUCKET=***
ENV DB_USER=***
ENV DB_PASSWORD=***
ENV DB_PORT=***
ENV DB_HOST=***
ENV DB_NAME=***
ENV DATABASE=***
ENV TABLE=***

# additional settings to startup the container
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

MAINTAINER Pietro Grandinetti
LABEL Description="Dockerized SUMO for standard datasets and reproducible research"

RUN apt-get update \
    && apt-get -y upgrade

RUN yes Y | apt install software-properties-common

RUN apt install -y git \
    && apt install -y wget \
    && apt install -y curl

RUN add-apt-repository ppa:sumo/stable -y \
    && apt update \
    && apt install -y sumo sumo-tools
RUN export SUMO_HOME=/usr/share/sumo
RUN git clone $MODEL_LOC ./sumodir

RUN alias python=python3.8
RUN apt install python3-pip -y

RUN apt install postgresql-server-dev-12 -y

RUN apt install -y python3-venv
RUN python3.8 -m venv /venv
ENV PATH=/venv/bin:$PATH

RUN git clone https://github.com/pgrandinetti/standard-traffic-data stdata
RUN cd stdata \
    && git checkout aws_pipeline \
    && pip3 install -r requirements.txt

RUN cd stdata && pip3 install -e ./

CMD export SUMO_HOME=/usr/share/sumo \
    && /bin/bash stdata/std_traffic/pipelines/sumoToAws.sh \
    SUMO_COMMAND="-c ./sumodir/scenario/$SUMO_COMMAND" \
    SUMO_MODEL_PREFIX=$SUMO_MODEL_PREFIX \
    SUMO_OUTPUT_FILE=$SUMO_OUTPUT_FILE \
    SUMO_TO_CSV=/usr/share/sumo/tools/xml/xml2csv.py \
    S3=$S3 \
    DB=$DB \
    AWS_KEY_ID=$AWS_KEY_ID \
    AWS_SECRET_KEY=$AWS_SECRET_KEY \
    AWS_REGION=$AWS_REGION \
    DB_HOST=$DB_HOST \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    DB_HOST=$DB_HOST \
    TABLE=$TABLE \
    S3_BUCKET=$S3_BUCKET \
    CLEANUP=$CLEANUP
