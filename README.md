# Overview:
Sets up web service container to communicate with Grafana front end and Vitess backend.
Currently includes sos, numsos, sosdb-ui, and sosdb-grafana.

## Build container:

docker build -t ogcws:v1 .

## Run container:

docker run -d \
        -v ~jenos/webservices/config:/config \
        -v ~jenos/webservices/data/sos:/data/sos \
        -v ~jenos/webservices/log:/log \
	-v /etc/localtime:/etc/localtime \
	-e apacheUID=`id -u` \
	-e apacheGID=`id -g` \
	-p 8088:8080/tcp --name webservices ogcws:v1


## Notes to implement.

### Build container _optional_ adjustments (can be changed after container started):
* custom/init.sh: admin/pass user info
* httpd-wsgi.conf file: Port number for web. (can be changed later as well)

### Run container recommended adjustments:
* Mapped folder locations. Please map config, data, log, localtime similar to above.
* Mapped port numbers for container httpd to host listening port.
* apacheUID and apacheGID environments are optional but recommended to avoid permissions issues on the mapped folders owned by an external user. Note, these are intended to be set to the user running the container and will become "apache" within the container context.

### After container started:
* Recommend changing default admin password via web browser to port.
* /config/settings.py has an ALLOWED_HOSTS section that may need the IP or hostname of the grafana host/container added.
* /config/httpd-wsgi.conf: Port number for web. (if change desired from container build setting above)

