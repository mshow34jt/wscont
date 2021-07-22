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
	-p 8088:8080/tcp --name webservices ogcws:v1


## Notes to implement.

### Build container _optional_ adjustments (can be changed after container started):
* Dockerfile file: admin/pass user info
* httpd-wsgi.conf file: Port number for web.

### Run container recommended adjustments:
* Mapped folder locations. Please map config, data, log, localtime similar to above.
* Mapped port numbers for container httpd to host listening port.

### After container started:
* Adjust  /config/httpd-wsgi.conf file as needed.  (e.g. if mapped port was changed above)
* Recommend changing default admin password via web browser to port.
