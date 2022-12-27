#!/bin/bash

docker-compose down

if [[ $RESET_HARD == "1" ]]
then
    docker system prune -a --force
    docker volume rm "$(docker volume ls -q)"
fi

docker-compose up --build -d nginx

# Pause here until http://worldpeace.cloud response code is 200
while : ; do
    RESPONSE_CODE=$(curl --output /dev/null --connect-timeout 5 --max-time 20 --write-out '%{http_code}' -s -S http://worldpeace.cloud)
    echo "$RESPONSE_CODE"
    echo "testing with curl"
    [[ $RESPONSE_CODE == "200" ]] || break
done
