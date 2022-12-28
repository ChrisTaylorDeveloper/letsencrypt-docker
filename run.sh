#!/bin/bash -xv

function domain_response_code () {
    echo "$(curl --output /dev/null --connect-timeout 5 --max-time 10 \
        --write-out '%{http_code}' -s -S http://worldpeace.cloud)"
}

function certbot_exit_code () {
    docker-compose ps | grep certbot | grep -o "exited (0)"
    echo $?
}

docker-compose down

if [[ $CERTBOT_DOCKER_PRUNE == "1" ]]
then
    docker system prune -a --force
fi

if [[ $CERTBOT_DOCKER_VOLS_REMOVE == "1" ]]
then
    docker volume rm $(docker volume ls -q)
fi

# exit if docker-compose didn't end well
if ! docker-compose up --build -d nginx;
then
    exit 1
fi

# pause here until http://worldpeace.cloud responses with 200
until [[ $(domain_response_code) -eq 200 ]]; do
    sleep 2
done

docker-compose up --build -d certbot

# pause here until certbot ends well
until [[ $(certbot_exit_code) -eq 0 ]]; do
    sleep 2
done
