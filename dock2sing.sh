#!/bin/bash
uid=`id -u`
gid=`id -g`
un=`id -un`
gn=`id -gn`
singdef=./Singularity.def
initsh=./custom/init-sing.sh
httpdwsgi=./custom/httpd-wsgi-sing.conf
/bin/cp -f ./custom/init.sh $initsh
/bin/cp -f ./custom/httpd-wsgi.conf $httpdwsgi
pip3 install spython
spython recipe Dockerfile $singdef
perl -pi -e "s/^LD_LIBRARY_PATH=/export LD_LIBRARY_PATH=/g" $singdef
perl -pi -e "s/^PATH=/export PATH=/g" $singdef
perl -pi -e "s/^PYTHONPATH=/export PYTHONPATH=/g" $singdef
perl -pi -e "s/^chown -R apache:apache/chown -R $uid:$gid/g" $singdef
perl -pi -e "s/^chown -R apache:apache/chown -R $uid:$gid/g" $initsh
perl -pi -e "s,^exec /bin/bash /bin/bash -c,exec /bin/bash -c,g" $singdef
perl -pi -e 's,^/usr/bin/su -c "/usr/sbin/httpd -D FOREGROUND" apache,/usr/sbin/httpd -D FOREGROUND,g' $initsh
perl -pi -e "s/User apache/User $un/g" $singdef
perl -pi -e "s/Group apache/Group $gn/g" $singdef
perl -pi -e "s/#dock2sing_only//g" $singdef

mkdir -p /var/run/httpd || echo -e "Warning: /var/run/httpd not writeable. With permissions, run:\nmkdir -p /var/run/httpd && chown $un:$gn /var/run/httpd\nbefore running instance."

cat <<EOF

Steps to build image (sif file) and start instance (example):
  Be sure to setup "fakeroot" requirements first if not there already.
    https://sylabs.io/guides/3.5/user-guide/cli/singularity_config_fakeroot.html
    singularity config fakeroot --add $un
  mkdir -p ~/webservices/config ~/webservices/log
  cd $OLDPWD
  singularity build --fakeroot ~/webservices/ogcws.sif Singularity.def
  cd ~webservices
  singularity instance start --bind ./config:/config,./log:/log,/run  ./ogcws.sif ogcws
EOF

