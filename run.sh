#!/bin/bash -xv

function domain_response_code () {
    echo "$(curl --output /dev/null --connect-timeout 5 --max-time 10 \
        --write-out '%{http_code}' -s -S http://worldpeace.cloud)"
}

# Start with all Docker containers shutdown.
docker-compose down

# Clean up after previous runs 
echo $1 | sudo -S git clean -fd
git checkout -- .
mkdir ${VOLUME_CERTBOT_ETC}

# Setting these variables with prune Docker and delete all Volumes. 
if [[ $CERTBOT_DOCKER_PRUNE == "1" ]]
then
    docker system prune -a --force
fi
if [[ $CERTBOT_DOCKER_VOLS_REMOVE == "1" ]]
then
    docker volume rm $(docker volume ls -q)
fi

# Run nginx for the first time and exit if there was a problem.
if ! docker-compose up --build -d nginx;
then
    echo "nginx service failed"
    exit 1
fi

# Pause here until http://worldpeace.cloud responses with 200.
until [[ $(domain_response_code) -eq 200 ]]; do
    sleep 2
done

# Run certbot and exit if there was a problem.
# if ! docker-compose up --build -d certbot;
# then
#     echo "certbot service failed"
#     exit 1
# fi

# Swap over the basic nginx conf for the https conf.
# rm ./nginx_conf/nginx.conf
# cp ./nginx-https.conf ./nginx_conf/nginx.conf

# Restart nginx using the https conf. 
# docker-compose restart nginx
