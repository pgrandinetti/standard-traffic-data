FROM ubuntu:20.04

ENV SUMO_HOME=/usr/share/sumo
ENV XML2CSV=/usr/share/sumo/tools/xml/xml2csv.py

ARG MODEL_LOC=https://github.com/lcodeca/MoSTScenario
ARG MODEL_DIR=scenario
ARG SUMO_COMMAND="most.sumocfg -e 14600 --fcd-output"
ARG SUMO_MODEL_PREFIX=most
ARG SUMO_OUTPUT_FILE=saveout

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

RUN sumo -c sumodir/$MODEL_DIR/$SUMO_COMMAND $SUMO_OUTPUT_FILE.xml
RUN python3 $XML2CSV ./$SUMO_MODEL_PREFIX.$SUMO_OUTPUT_FILE.xml
RUN /bin/bash 

#RUN alias python=python3.8
#RUN apt install python3-pip -y

#RUN apt install postgresql-server-dev-12 -y
#RUN git clone https://github.com/pgrandinetti/standard-traffic-data stdata
#RUN cd stdata \
#    && git checkout aws_pipeline \
#    && pip3 install -r requirements.txt

RUN /bin/bash stdata/std_traffic/pipelines/sumoToAws.sh \
    SUMO_COMMAND=
