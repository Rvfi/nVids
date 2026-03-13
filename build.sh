#!/bin/bash

docker build -t crcljrcs-vids:latest .

docker save crcljrcs-vids:latest | gzip > crcljrcs-vids.tar