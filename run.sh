#!/bin/bash -xv

function domain_response_code () {
    curl --output /dev/null --connect-timeout 5 --max-time 10 \
        --write-out '%{http_code}' -s -S http://worldpeace.cloud
}

function nginx_up {
    docker run --name nginx -d \
    -p "80:80" \
    -p "443:443" \
    -v certbot_etc:/etc/letsencrypt \
    -v certbot_var:/var/lib/letsencrypt \
    -v html:/usr/share/nginx/html \
    -v /home/dock/letsencrypt-docker/nginx_conf:/etc/nginx/conf.d \
    nginx:1.23.3
}

function certbot_up {
    docker run --name certbot -d \
    -v certbot_etc:/etc/letsencrypt \
    -v certbot_var:/var/lib/letsencrypt \
    -v html:/var/www/html \
    -v dhparam:/etc/ssl/certs \
    certbot/certbot \
    certonly --webroot --webroot-path=/var/www/html --email chris@christaylordeveloper.co.uk --agree-tos --no-eff-email --force-renewal -d worldpeace.cloud --staging --break-my-certs
}


function service_exit_code {
    docker inspect "$1" --format='{{.State.ExitCode}}'
}

# Cleanup Docker.
docker_list=$(docker ps -aq)
if [[ -n ${docker_list} ]];
then
    docker stop ${docker_list}
fi

docker_list=$(docker ps -aq)
if [[ -n ${docker_list} ]];
then
    docker rm ${docker_list}
fi

vols_list=$(docker volume ls -q)
if [[ -n ${vols_list} ]];
then
    docker volume rm ${vols_list}
fi

docker system prune -a --force

# Cleanup git.
echo "$1" | sudo -S git clean -fd
git checkout -- .

# Create Docker Volumes.
docker volume create certbot_var
docker volume create certbot_etc
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

# Run nginx for the first time.
nginx_cont=$(nginx_up)
until [[ $(service_exit_code "${nginx_cont}") -eq 0 ]]; do
    sleep 3
done

# Pause here until http://worldpeace.cloud responses with 200.
# until [[ $(domain_response_code) -eq 200 ]]; do
#     sleep 3
# done

# Run certbot service.
# certbot_cont=$(certbot_up)
# certbot_status=$(docker inspect "${certbot_cont}" --format='{{.State.ExitCode}}')
# if [[ "${certbot_status}" -ne 0 ]];
# then
#     echo "certbot service failed"
#     exit 1
# fi

# Stop nginx.
# docker stop ${nginx_cont}
# docker rm ${nginx_cont} 

# Swap over the basic nginx conf for the https conf.
# rm ./nginx_conf/nginx.conf
# cp ./nginx-https.conf ./nginx_conf/nginx.conf

# Start nginx.
# nginx_up
