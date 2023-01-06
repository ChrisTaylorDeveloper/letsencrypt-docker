#!/bin/bash -xv

function domain_response_code () {
    echo "$(curl --output /dev/null --connect-timeout 5 --max-time 10 \
        --write-out '%{http_code}' -s -S http://worldpeace.cloud)"
}

function nginx_up () {
    docker run --name nginx -d \
        -p "80:80" \
        -p "443:443" \
        -v certbot_etc:/etc/letsencrypt \
        -v certbot_var:/var/lib/letsencrypt \
        -v html:/usr/share/nginx/html \
        -v /home/dock/letsencrypt-docker/nginx_conf:/etc/nginx/conf.d \
        nginx:1.23.3
}

# Cleanup Docker.
docker stop "$(docker ps -aq)"
docker rm "$(docker ps -aq)"
docker volume rm "$(docker volume ls -q)"
docker system prune -a --force

# Cleanup git.
echo "$1" | sudo -S git clean -fd
git checkout -- .

# Make dir needed later on.
mkdir /home/dock/letsencrypt-docker/certbot_etc

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

# Run nginx for the first time.
nginx_cont=$(nginx_up)
nginx_status=$(docker inspect "${nginx_cont}" --format='{{.State.ExitCode}}')
if [[ "${nginx_status}" -ne 0 ]];
then
    echo "nginx service failed"
    exit 1
fi

# Pause here until http://worldpeace.cloud responses with 200.
until [[ $(domain_response_code) -eq 200 ]]; do
    sleep 2
done

# Run certbot service for the first time.
certbot_cont=$(docker run --name certbot -d \
    -v certbot_etc:/etc/letsencrypt \
    -v certbot_var:/var/lib/letsencrypt \
    -v html:/var/www/html \
    -v dhparam:/etc/ssl/certs \
    certbot/certbot \
    certonly --webroot --webroot-path=/var/www/html --email chris@christaylordeveloper.co.uk --agree-tos --no-eff-email --force-renewal -d worldpeace.cloud --staging --break-my-certs)
certbot_status=$(docker inspect "${certbot_cont}" --format='{{.State.ExitCode}}')
if [[ "${certbot_status}" -ne 0 ]];
then
    echo "certbot service failed"
    exit 1
fi

# Should probably stop nginx here
docker stop ${nginx_cont} 

# Swap over the basic nginx conf for the https conf.
rm ./nginx_conf/nginx.conf
cp ./nginx-https.conf ./nginx_conf/nginx.conf

# Should probably start nginx here!!!
# Restart nginx using the https conf. 
# docker-compose restart nginx
