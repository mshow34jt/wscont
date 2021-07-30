# Overview:
Sets up web service container to communicate with Grafana front end and Vitess backend.
Currently includes sos, numsos, sosdb-ui, and sosdb-grafana, httpd (apache).

## Build container:

	docker build -t ogcws:v1 .

## Run container:

Example:

	docker run -d \
	-v ~jenos/webservices/config:/config \
	-v ~jenos/webservices/data/sos:/data/sos \
	-v ~jenos/webservices/log:/log \
	-v /etc/localtime:/etc/localtime \
	-p 8088:8080/tcp --name webservices ogcws:v1

Optional to ensure container apache process can access mapped volumes:

	-e apacheUID=`id -u` (system level docker service - see below)
	-e apacheGID=`id -g` (system level docker service - see below)
	---OR---
	-e rootless=1 (user level docker service - see below)

## Notes to implement.

### Build container _optional_ adjustments (can be changed after container started):
* custom/init.sh: admin/pass user info
* httpd-wsgi.conf file: Port number for web. (can be changed later as well)

### Run container recommended adjustments:
* Mapped folder locations. Please map config, data, log, localtime similar to above.
* Mapped port numbers for container httpd to host listening port. (point grafana to port 8088 in example above)
* apache user within container must have access to mapped data, log, and config folders. This is accomplished in different ways depending on whether the docker service is run as root or a user (rootless). The container is still expected to be launched/owned by non-root user in both cases.
Root docker service (most common):
apacheUID and apacheGID environments are set to ensure access to config, log, and data folders specified. These are usally set to the user running the container and will become "apache" within the container context.
Rootless docker service (run as user):
"rootless" environment: Required to be set to "1" when running container under user level docker service. Adds apache user to container "root" group in container context, which translates to the user's group on the host environment.  NOT RECOMMENDED for running container under system docker service.

### After container started:
* Recommend changing default admin password via web browser to port.
* /config/settings.py has an ALLOWED_HOSTS section that may need the IP or hostname of the grafana host/container added.
* /config/httpd-wsgi.conf: Port number for web. (if change desired from container build setting above, 8080)

