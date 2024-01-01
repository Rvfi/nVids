#!/bin/bash

docker build -t nvids:latest .

docker save nvids:latest | gzip > nvids.tar