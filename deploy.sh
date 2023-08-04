#!/bin/bash

aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 945110345271.dkr.ecr.us-west-1.amazonaws.com

docker build -t nvids .

docker tag nvids:latest 945110345271.dkr.ecr.us-west-1.amazonaws.com/nvids:latest

docker push 945110345271.dkr.ecr.us-west-1.amazonaws.com/nvids:latest

aws ecs update-service --cluster nvids --service nvids-discord-bot --force-new-deployment --no-cli-pager
