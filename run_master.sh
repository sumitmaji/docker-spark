#!/bin/bash

docker run -d -h node01  --name consul -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500 -p 53:53/udp progrium/consul -server -advertise 11.0.0.2 -bootstrap-expect 2

docker run -d -v /var/run/docker.sock:/tmp/docker.sock --link consul:consul --name registrator -h registrator gliderlabs/registrator:latest consul://11.0.0.2:8500

#docker run -d -p 444:44444 -p 2122:2122 -p 50070:50070 -p 54310:54310 --dns 172.17.0.2 --dns 8.8.8.8 --dns-search service.consul -e "SERVICE_2122_NAME=node01" -e "SERVICE_2122_ID=node01.2122" --name hadoop -h node01 sumit/hadoop:latest /etc/bootstrap.sh -d master 

docker run -d -p 444:44444 -p 50010:50010 -p 2122:2122 -p 50070:50070 -p 54310:54310 -p 9000:9000 --dns 172.17.0.2 --dns 8.8.8.8 --dns-search service.consul -e "SERVICE_2122_NAME=node01" -e "SERVICE_2122_ID=node01.2122" --name spark -h node01 sumit/spark:latest /etc/bootstrap.sh -d master
