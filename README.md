# Overview:
Sets up web service container to communicate with Grafana front end and Vitess backend.
Currently includes sos, numsos, sosdb-ui, and vitess-grafana, httpd (apache).

## Build container:
	In same folder as Dockerfile (or use -f <path>/Dockerfile)
	docker build -t ogcws:v1 .

## Run container:

Example:

	docker run -d \
	-v ~/webservices/config:/config \
	-v ~/webservices/log:/log \
	-v /etc/localtime:/etc/localtime \
	-p 8080:8080/tcp --name webservices ogcws:v1

## Notes to implement.

### Build container _optional_ adjustments (can be changed after container started):
* Port number defaults to 8080
* User/pass from admin/pass

### Run container recommended adjustments:
* Mapped folder locations. Please map config, data, log, localtime similar to above.
* Mapped port numbers for container httpd to host listening port. (point grafana to port 8080 in example above)

### After container started:
* /config/settings.py has an ALLOWED_HOSTS section that may need the IP or hostname of the grafana host/container added.
* /config/httpd.conf: Port number for web. (if change desired from container build setting above, 8080)

## Singularity Instructions
In the wscont folder with the Dockerfile, run ./dock2sing.sh script as the user
you plan to run the singularity container as.  Follow instructions from there,
or from below:

Steps to build image (sif file) and start instance (example):
* In the wscont/ folder, as the container owner user, run ./dock2sing.sh (generates Singularity.def)
* Be sure to setup "fakeroot" requirements first if not there already.
*    https://sylabs.io/guides/3.5/user-guide/cli/singularity_config_fakeroot.html
*    e.g.:
*    singularity config fakeroot --add $USER
*  mkdir -p ~/webservices/config ~/webservices/log
*  cd <PATH>/wscont
*  singularity build --fakeroot ~/webservices/ogcws.sif Singularity.def
*  cd ~/webservices
*  singularity instance start --bind ./config:/config,./log:/log,./log:/run ./ogcws.sif ogcws

