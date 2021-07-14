# Set up build image
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

WORKDIR /source
RUN git clone https://github.com/nick-enoent/sosdb-ui && \
    cd sosdb-ui && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/var/www/ovis_web_svcs && \
    make && \
    make install

WORKDIR /source
RUN git clone https://github.com/nick-enoent/sosdb-grafana && \
    cd sosdb-grafana && \
    ./autogen.sh && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=/var/www/ovis_web_svcs && \
    make && \
    make install

# Set up running image
FROM centos:7 AS runner

RUN yum update -y && \
    yum install -y python3 \
		httpd &&\
    pip3 install cython django==2.1.0 django-cors-headers==2.1.0 pandas && \
    yum clean all

COPY --from=build /usr/local/sos /usr/local/sos
COPY --from=build /var/www/ovis_web_svcs /var/www/ovis_web_svcs
COPY --from=build /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
                  /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so
COPY wsgi-httpd.conf /etc/httpd/conf.d/wsgi.conf
COPY settings.py /var/www/ovis_web_svcs/sosgui/

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/usr/local/sos/bin:$PATH
ENV PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages

WORKDIR /var/www/ovis_web_svcs
RUN ln -s /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
          /usr/lib64/httpd/modules/mod_wsgi.so && \
    echo "LoadModule wsgi_module modules/mod_wsgi.so" > /etc/httpd/conf.modules.d/10-wsgi.conf && \
    mkdir -p /var/log/ovis_web_svcs /data/sos && \
    chown -R :apache /var/www/ovis_web_svcs && \
    chmod -R g+rw /var/www/ovis_web_svcs && \
    rm -f /etc/httpd/logs && \
    ln -s /var/log/ovis_web_svcs /etc/httpd/logs && \
    python3 manage.py migrate && \
    python3 manage.py migrate --run-syncdb && \
    echo "from sosdb_auth.models import SosdbUser; SosdbUser.objects.create_superuser('admin', 'admin@example.com', 'pass')" | python3 manage.py shell && \
    python3 manage.py collectstatic && \
    echo "for file in settings.log sosgui.log ; do" >> /usr/local/bin/init.sh && \
    echo "  if [ ! -f \$file ]; then" >> /usr/local/bin/init.sh && \
    echo "    touch \$file" >> /usr/local/bin/init.sh && \
    echo "    chown :apache \$file" >> /usr/local/bin/init.sh && \
    echo "    chmod g+rw \$file" >> /usr/local/bin/init.sh && \
    echo "  fi" >> /usr/local/bin/init.sh && \
    echo "done" >> /usr/local/bin/init.sh && \
    echo "/usr/sbin/httpd -D FOREGROUND" >> /usr/local/bin/init.sh && \
    chmod +x /usr/local/bin/init.sh

CMD ["/bin/bash", "-c", "/usr/local/bin/init.sh"]

