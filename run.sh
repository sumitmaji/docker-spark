#!/bin/bash

docker run -d -p 8998:8998 --name spark -h spark --net cloud.com sumit/spark:latest /etc/bootstrap.sh -d


