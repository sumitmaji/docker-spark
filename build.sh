#!/bin/bash
docker build --build-arg REPOSITORY_HOST=http://192.168.1.5:8181 -t sumit/spark:latest .
