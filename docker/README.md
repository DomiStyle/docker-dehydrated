# dehydrated dockerized

![](https://github.com/DomiStyle/docker-dehydrated/raw/master/docker/logo.png)

## Introduction

This image includes includes [dehydrated](https://github.com/lukas2511/dehydrated) and [Lexicon](https://github.com/AnalogJ/lexicon) to easily create Let's Encrypt certificates for multiple domains, wildcards and via HTTP-01 or DNS-01 validation. Most configuration is done with environment variables.

## First run

Let's Encrypt requires you to accept their EULA and register for a new account before you can request certificates. To do so, simply start the container with the REGISTER environment variable. Don't forget to mount the volumes properly or the registration won't persist.

A configuration file will be generated for you upon start, no extra configuration is needed for HTTP-01 or DNS-01 validation.

To trigger the registration process run:

    docker run -it --rm -e REGISTER=true -v /srv/dehydrated/data:/data domistyle/dehydrated

After which your credentials and default configuration will be created in /srv/dehydrated/data.

**Create a domains.txt in your data folder after registration in order to specify which domains you want to request certificates for. See the [domains.txt documentation](https://github.com/DomiStyle/docker-dehydrated/blob/master/docs/domains_txt.md) for more details.**

## Examples

### DNS-01 validation with Lexicon

DNS validation is the simplest validation type and can be configured completely with environment variables. DNS-01 validation requires you to use a nameserver provider that is supported by Lexicon. A complete list of supported providers can be found [here](https://github.com/AnalogJ/lexicon#providers).

#### API with Token

If your provider uses tokens to authenticate you, you can request certificates like this:

    docker run -it --rm -e PARAM_CHALLENGETYPE=dns-01 -e PROVIDER=<provider name> -e LEXICON_<PROVIDER NAME>_TOKEN=<your token> -v /srv/dehydrated/data:/data -v /srv/dehydrated/certs:/data/certs domistyle/dehydrated

* \<provider name\> is the name taken from the Lexicon provider list in lower case, for example: digitalocean, cloudflare, ...

* \<PROVIDER NAME\> is the same as above but in uppercase, for example: DIGITALOCEAN, CLOUDFLARE

* \<your token\> is the token you received from your provider for their API

#### API with Password

If your provider uses passwords to authenticate you, you can request certificates like this:

    docker run -it --rm -e PARAM_CHALLENGETYPE=dns-01 -e PROVIDER=<provider name> -e LEXICON_<PROVIDER NAME>_USERNAME=<your username> -e LEXICON_<PROVIDER NAME>_PASSWORD=<your password> -v /srv/dehydrated/data:/data -v /srv/dehydrated/certs:/data/certs domistyle/dehydrated

* \<provider name\> is the name taken from the Lexicon provider list in lower case, for example: digitalocean, cloudflare, ...

* \<PROVIDER NAME\> is the same as above but in uppercase, for example: DIGITALOCEAN, CLOUDFLARE

* \<your username\> is the username you use to login

* \<your password\> is the password you use to login

### HTTP-01 validation

HTTP-01 validation is slightly more complicated than DNS-01 validation because it requires a correctly configured webserver in order to work, which is not included in this container. For a example configuration take a look at the section below for combined usage.

    docker run -it --rm -e PARAM_CHALLENGETYPE=http-01 -v /srv/dehydrated/data:/data -v /srv/dehydrated/certs:/certs -v /srv/dehydrated/challenges:/data/challenges domistyle/dehydrated

You will have to mount ``/srv/dehydrated/challenges`` into your webserver container and handle requests from Let's Encrypt accordingly.

### Using both HTTP-01 and DNS-01 at the same time

    nginx:
    image: nginx
    restart: always
    ports:
        - 80:80
        - 443:443
    volumes:
        - ./certs:/etc/nginx/certs:ro
        - ./challenges:/var/www/challenges:ro
        - ./config:/etc/nginx/conf.d:ro
        - ./dh:/etc/nginx/dh:ro
    environment:
        TZ: Europe/Berlin
    letsencrypt-dns:
    image: domistyle/dehydrated
    volumes:
        - ./dehydrated-dns:/data
        - ./certs:/data/certs
    environment:
        - PARAM_CHALLENGETYPE=dns-01
        - PROVIDER=digitalocean
        - LEXICON_DIGITALOCEAN_TOKEN=000000000000000000
        - TZ=Europe/Berlin
    letsencrypt-http:
    image: domistyle/dehydrated
    volumes:
        - ./dehydrated-http:/data
        - ./certs:/data/certs
        - ./challenges:/data/challenges
    environment:
        - PARAM_CHALLENGETYPE=http-01
        - TZ=Europe/Berlin

The docker-compose file can be found [here](https://github.com/DomiStyle/docker-dehydrated/blob/master/docker/docker-compose.yml).

Other things needed in order for nginx to run:

* Create a Diffie-Hellman key, if you want to use one: ``openssl dhparam -out ./dh/dhparam.pem 2048``
* Add your default.conf in ./config

        server
        {
            listen 80 default_server;

            location ^~ /.well-known/acme-challenge
            {
                default_type "text/plain";
                alias /var/www/challenges;
            }

            location /
            {
                return 301 https://$host$request_uri;
            }
        }

* Create any other site you need as usual after you received your certificates

## Automatic renew

Since certificates signed by Let's Encrypt expire after 90 days they need to be renewed automatically. By default the container exits after running dehydrated, expecting to be run again from an external source.

**Don't forget to reload your webserver too.**

You can do this in nginx with ``nginx -s reload`` or ``systemctl reload nginx``.

### Host Cronjob

The cronjob service running on the host can be used to start the container(s) automatically.

    0 5 * * * docker-compose -f /path/to/docker-compose.yml start letsencrypt-dns
    0 5 * * * docker-compose -f /path/to/docker-compose.yml start letsencrypt-http

To also reload nginx you can add the following line:

    0 6 * * * docker-compose -f path/to/docker-compose.yml exec nginx nginx -s reload

### Orchestrator

Many orchestrators allow creating cronjobs to start a container at a spcified time.

For example, Rancher 1.6 supports the cron.schedule label while Kubernetes allows adding a CronJob directly.

### Internal

The container comes with an environment variable to keep it running forever and repeat certificate requests automatically. While this is not recommended, it allows you to get started quickly if no alternative is available.

    docker run -e REPEAT=true -e REPEAT_INTERVAL=86400 domistyle/dehydrated

## Environment variables

The following environment variables are available:

| Variable  | Description | Default  | Required |
|-----------|-------------|----------|----------|
| `PARAM_CHALLENGETYPE` | Sets the challenge type for dehydrated | ``HTTP-01`` | No |
| `TZ` | Sets the time zone. Mostly useful for correct timestamps when logging | - | No |
| `PROVIDER` | Sets the provider to use (DNS-01 only) | - | No |
| `LEXICON_<PROVIDER NAME>_USERNAME` | Sets the username to use for a provider (DNS-01 only) | - | No |
| `LEXICON_<PROVIDER NAME>_TOKEN` | Sets the token to use for a provider (DNS-01 only) | - | No |
| `LEXICON_<PROVIDER NAME>_PASSWORD` | Sets the password to use for a provider (DNS-01 only) | - | No |
| `REPEAT` | Set to true to never exit the container and repeat the command every REPEAT_INTERVAL | - | No |
| `REPEAT_INTERVAL` | If REPEAT is set dehydrated will automatically be started every REPEAT_INTERVAL (in seconds) | - | No |
| `PARAM_HOOK` | The path for the hook script to execute for DNS-01 validation | ``/app/hook.sh`` | No |`

For more environment variables check the GitHub page for [dehydrated](https://github.com/lukas2511/dehydrated) and [Lexicon](https://github.com/AnalogJ/lexicon).

## Volumes

The following volumes can be mounted into the container:

| Path       | Description                                  | Required |
|------------|----------------------------------------------|----------|
|`/data`| Base directory for dehydrated | Yes |
|`/data/certs`| Can be used to save certificates to a different folder than the regular data directory | No |
|`/data/challenges`| Contains the challenges for HTTP-01 validation | No |
