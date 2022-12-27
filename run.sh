#!/bin/bash

docker-compose down

if [[ $RESET_HARD == "1" ]]
then
    docker system prune -a --force
    docker volume rm "$(docker volume ls -q)"
fi

docker-compose up --build -d nginx

# Pause here until http://worldpeace.cloud response code is 200
