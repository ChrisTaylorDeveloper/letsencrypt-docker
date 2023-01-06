#!/bin/bash -xv

function domain_response_code () {
    echo "$(curl --output /dev/null --connect-timeout 5 --max-time 10 \
        --write-out '%{http_code}' -s -S http://worldpeace.cloud)"
}

# Start with Containers shutdown.
docker-compose down

# Cleanup git.
echo $1 | sudo -S git clean -fd
git checkout -- .

# Clean up dirs.
#mkdir ${VOLUME_CERTBOT_ETC}

# Clean up docker.
docker system prune -a --force
docker volume rm $(docker volume ls -q)

# Create Docker Volumes.
docker volume create certbot_var

docker volume create \
    --driver local \
    -o type=none \
    -o o=bind \
    -o device=/home/dock/letsencrypt-docker/certbot_etc \
    certbot_etc

docker volume create \
    --driver local \
    -o type=none \
    -o o=bind \
    -o device=/home/dock/letsencrypt-docker/html \
    html

docker volume create \
    --driver local \
    -o type=none \
    -o o=bind \
    -o device=/home/dock/letsencrypt-docker/dhparam \
    dhparam 

# Run nginx for the first time and exit if there was a problem.
# if ! $(docker-compose up --build -d nginx);
# then
#     echo "nginx service failed"
#     exit 1
# fi

# Pause here until http://worldpeace.cloud responses with 200.
# until [[ $(domain_response_code) -eq 200 ]]; do
#     sleep 2
# done

# Run certbot and exit if there was a problem.
# if ! $(docker-compose up --build -d certbot);
# then
#     echo "certbot service failed"
#     exit 1
# fi

# Should probably stop nginx here

# Swap over the basic nginx conf for the https conf.
# rm ./nginx_conf/nginx.conf
# cp ./nginx-https.conf ./nginx_conf/nginx.conf

# Should probably start nginx here!!!
# Restart nginx using the https conf. 
# docker-compose restart nginx
