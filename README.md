# Standard Traffic Data

The 1st fully open-source repository for road traffic timeseries.

This repository is a mix of engineering, data science and knowledge. The underling topic is that of road traffic timeseries analysis: vehicles (or, in general) objects move in a road network and it's worth spending time to study the data, to ask questions and to uncover patterns.

Everything you will see here is open-source and reproducible:

 - Data generation is reproducible via scripting and Docker files.
 - The generated data is published and can be downloaded by everybody (no registration required).
 - Analysis, studies and techniques are published in form of articles and/or reproducible notebooks.

## How to contribute

The real aim of this project is to involve as many people as possible. Whether you are an experienced engineer, data scientist or a student (isn't everybody?), if you are interested in playing with these datasets then please go ahead and have fun. We hope you'll get in touch and collaborate, because we believe open-source is meant to produce and share knowledge. There's already some amazing people sharing their experience with us, and we'd love for you to be the next one.

If that's what you believe too, open an issue now and explain what ideas you have for your next article with this data.

But if for some reason you'd rather not, then you can simply download the data and use it for your own purpose. You don't need to ask permission. Take note of the licence though: it's MIT.

## Repository structure

Here's how you can navigate this repository after you fork it.

  - `knowledge/` is where you should start. The directory contains all articles and notebooks with the studies other contributors have made and published. Remember, you can be the next one!
  - `std_traffic` is a Python package. You can install it with `pip install -e .`.
  - `std_traffic/pipelines/` is where the software pipelines for data generation, processing and storage are (sort of ETL scripts).
  - `std_traffic/utils/` contains Python functions that can be useful for a variety of things, mainly interacting with cloud storage and databases.
  - `scripts/` contains ... executable scripts!


## The data

Whenever we generate or collect data, we publish it for everybody's benefits. Next is a list of all datasets, or databases, that we have.

**Principality of Monaco**

These are timeseries of simulated road traffic data. The simulator used is SUMo, and the simulated city is the Principality of Monaco. We used the previous work of researchers at Communication Systems Department of Sophia-Antipolis, France. We took their (quite complex!) work and made it 100% reproducible with a Docker file. The story is told in the introduction of [this article](https://github.com/pgrandinetti/standard-traffic-data/blob/main/knowledge/How_Fast_Would_You_Drive_In_Monaco.ipynb).

For a description of the data, read the introduction of [this other article](https://github.com/pgrandinetti/standard-traffic-data/blob/main/knowledge/Urban_Traffic_Data_Exploratory_Analysis.ipynb).

For more information about the ETL process, read [this page](https://github.com/pgrandinetti/standard-traffic-data/tree/main/std_traffic/pipelines#dockerized-pipeline).

| Time horizon | File size | Download |
| ------------ | --------- | -------- |
| 4am - 6:30am |   200 MB  | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_0600_1_5.csv) |
| 4am - 7am    |   686 MB  | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_0700_1_5.csv) |
| 4am - 8am    |   1.4 GB  | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_0800_1_5.csv) |
| 4am - 8:30am |   2 GB    | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_0830_1_5.csv) |
| 4am - 9am    |  2.5 GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_0900_1_5.csv) |
| 4am - 10am   |  3.9 GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_1000_1_5.csv) |
| 4am - 11am   |  5.2 GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_1100_1_5.csv) |
| 4am - 12pm   |  6.2 GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_1200_1_5.csv) |
| 4am - 1pm    |    7 GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_1300_1_5.csv) |
| 4am - 2pm    |   7+ GB   | [link](https://standard-traffic-data.s3.us-east-2.amazonaws.com/most_0400_1400_1_5.csv) |


We have also saved the same data in a database that is accessible via the internet. This is the better approach for statistical sampling and large data, instead of downloading a huge CSV. See [this article](https://github.com/pgrandinetti/standard-traffic-data/blob/main/knowledge/How_Fast_Would_You_Drive_In_Monaco.ipynb) for a usage example.

Maintaining the database is a bit expensive for us, especially because this is a nonprofit, self-funded project. Therefore, we don't disclose the host and password, to avoid bots.

But know this: if you request access and tell us what's your idea, we will definitely share the database credentials with you. Nobody's request was ever rejected so far. Open an issue to start collaborating!

## Project contributors (submit a PR if your name is missing!)

The list is in alphabetical order (by last names).

- Ruggero Fabbiano - [LinkedIn](https://www.linkedin.com/in/ruggerofabbiano/)
- Pietro Grandinetti - [website](https://pete.world)
