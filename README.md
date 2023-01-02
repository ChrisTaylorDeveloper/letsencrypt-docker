# Let's Encrypt Docker 

```
export CERTBOT_DOCKER_PRUNE=1; \
export CERTBOT_DOCKER_VOLS_REMOVE=1; \
export VOLUME_CERTBOT_ETC=/home/dock/letsencrypt-docker/certbot_etc; \
./run.sh
```

## Resources
* https://www.digitalocean.com/community/tutorials/how-to-secure-a-containerized-node-js-application-with-nginx-let-s-encrypt-and-docker-compose
