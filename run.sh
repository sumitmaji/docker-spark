#!/bin/bash

docker run -it -e ENABLE_KRB='true' -p 8998:8998 --name spark -h spark.cloud.com --net cloud.com sumit/spark:latest -d


