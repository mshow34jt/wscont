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
ADD custom /custom
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/usr/local/sos/bin:$PATH
ENV PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages

WORKDIR /var/www/ovis_web_svcs
RUN ln -s /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
          /usr/lib64/httpd/modules/mod_wsgi.so && \
    echo "LoadModule wsgi_module modules/mod_wsgi.so" > /etc/httpd/conf.modules.d/10-wsgi.conf && \ 
    # Create convenience config folder for mapping
    mkdir -p /var/log/ovis_web_svcs /data/sos /config && \
    # Create convenience log link for mapping
    ln -s /var/log/ovis_web_svcs /log && \
    rm -f /etc/httpd/logs && \
    ln -s /var/log/ovis_web_svcs /etc/httpd/logs && \
    chown -R apache:apache /var/www/ovis_web_svcs /config && \
##    chmod -R g+rw /var/www/ovis_web_svcs && \
    rm -f /etc/localtime && \
    chmod +x /custom/init.sh

CMD ["/bin/bash", "-c", "/custom/init.sh"]
##ENTRYPOINT ["/bin/bash", "/custom/init.sh"]
##CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

