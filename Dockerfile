FROM ubuntu:20.04

ENV SUMO_HOME=/usr/share/sumo
ENV XML2CSV=/usr/share/sumo/tools/xml/xml2csv.py

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

RUN export SUMO_HOME=$SUMO_HOME
RUN alias python=python3.8
RUN apt install python3-pip -y

RUN apt install postgresql-server-dev-12 -y
RUN git clone https://github.com/pgrandinetti/standard-traffic-data stdata
RUN cd stdata \
    && git checkout aws_pipeline \
    && pip3 install -r requirements.txt

