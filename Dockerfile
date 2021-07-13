FROM centos:7 AS build

RUN yum update -y && yum group install -y "Development Tools" && \
    yum install -y cmake \
                   httpd-devel \
                   libevent-devel \
                   libyaml-devel \
                   mod_wsgi \
                   numpy \
                   openssl-devel \
                   python3 \
                   python36-devel \
                   sqlite3 \
                   which \
                   make \
                   automake \
                   autoconf \
                   libtool \
                   autogen \
                   git \
                   && pip3 install cython pandas mod_wsgi && \
    yum clean all

#COPY sos /build_sosdb
WORKDIR /source

RUN git clone https://github.com/ovis-hpc/sos && \
    cd sos && \
    export PYTHON=`which python3` && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/usr/local/sos --enable-python && \
    make && \
    make install && \
    cd ../.. && \
    git clone https://github.com/nick-enoent/numsos && \
    cd numsos && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/usr/local/sos --with-sos=/usr/local/sos && \
    make && \
    make install
#    make clean && \
#    tar czf sosdb_master.tgz -C /usr/fake_local . && \
#    tar xzf sosdb_master.tgz -C /usr/local

#COPY sosdb-ui /build_ui

WORKDIR /source
RUN git clone https://github.com/nick-enoent/sosdb-ui && \
    cd sosdb-ui && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/var/www/ovis_web_svcs && \
    make && \
    make install
#    make clean

WORKDIR /source
RUN git clone https://github.com/nick-enoent/sosdb-grafana && \
    cd sosdb-grafana && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/var/www/ovis_web_svcs && \
    make && \
    make install

FROM centos:7 AS runner

RUN yum update -y && \
    yum install -y python3 \
		httpd &&\
    pip3 install cython django==2.1.0 django-cors-headers pandas && \
    yum clean all

COPY --from=build /usr/local/sos /usr/local/sos
COPY --from=build /var/www/ovis_web_svcs /var/www/ovis_web_svcs
COPY --from=build /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
                  /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so
COPY wsgi-httpd.conf /etc/httpd/conf.d/wsgi.conf
COPY settings.py /var/www/ovis_web_svcs/sosgui/

#RUN tar xvzf /usr/local/sosdb_master.tgz -C /usr/local
#COPY --from=build /app /app

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/usr/local/sos/bin:$PATH
ENV PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages

WORKDIR /var/www/ovis_web_svcs
RUN ln -s /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
          /usr/lib64/httpd/modules/mod_wsgi.so && \
    echo "LoadModule wsgi_module modules/mod_wsgi.so" > /etc/httpd/conf.modules.d/10-wsgi.conf && \
    mkdir -p /var/log/ovis_web_svcs /data/sos && \
    touch /var/log/ovis_web_svcs/settings.log /var/log/ovis_web_svcs/sosgui.log && \
    chown :apache /var/log/ovis_web_svcs/settings.log /var/log/ovis_web_svcs/sosgui.log && \
    chmod g+w /var/log/ovis_web_svcs/settings.log /var/log/ovis_web_svcs/sosgui.log && \
#    cp -r templates static /var/www/ovis_web_svcs && \
    python3 manage.py migrate && \
    python3 manage.py migrate --run-syncdb && \
    echo "from sosdb_auth.models import SosdbUser; SosdbUser.objects.create_superuser('admin', 'admin@example.com', 'pass')" | python3 manage.py shell && \
    python3 manage.py collectstatic
#CMD ["python3", "manage.py", "runserver", "0.0.0.0:8080"]
#CMD ["python3", "manage.py", "collectstatic"]
ENTRYPOINT ["/usr/sbin/httpd", "-D", "FOREGROUND"]

