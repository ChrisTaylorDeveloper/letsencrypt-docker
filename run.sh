#!/bin/bash

docker-compose down

if [[ $RESET_HARD == "1" ]]
then
    docker system prune -a --force
    docker volume rm "$(docker volume ls -q)"
fi

docker-compose up --build -d nginx

# Pause here until http://worldpeace.cloud response code is 200
RESPONSE_CODE=domain_response_code
while [ $RESPONSE_CODE != "200" ]; do
    RESPONSE_CODE=domain_response_code
done

domain_response_code () {
    CODE="$(curl --output /dev/null --connect-timeout 5 --max-time 20 --write-out '%{http_code}' -s -S http://worldpeace.cloud)"
    echo "$CODE"
    return "$CODE"
}
