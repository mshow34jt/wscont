Overview:
Sets up web service container to communicate with Grafana front end and Vitess backend.
Currently includes sos, numsos, sosdb-ui, and sosdb-grafana.

Build container:
docker build -t ogcws:v1 .

Run container:
docker run -d -v ~jenos/work/sosdata:/data/sos -v ~jenos/work/soslogs:/var/log/ovis_web_svcs -v /etc/localtime:/etc/localtime -p 8088:8080/tcp --name webservices ogcws:v1

Recommended to map out data and log targets, change in supplied configs if modifying.

