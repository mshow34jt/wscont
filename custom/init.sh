set -x 
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/local/sos/bin:$PATH
export PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages
# Clear any old pid files
rm -rf /run/httpd

for file in httpd.conf httpd-wsgi.conf settings.py db.sqlite3 ; do
	if [ ! -f /config/$file ]; then
        cp /custom/$file /config/
	fi
done
mkdir -p /run/httpd
chown -R apache:apache /config /log /run/httpd

/usr/bin/su -c "/usr/sbin/httpd -D FOREGROUND" apache

