set -x 
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/local/sos/bin:$PATH
export PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages
# Clear any old pid files
rm -f /run/httpd/httpd.pid

#for file in /var/log/ovis_web_svcs/settings.log /var/log/ovis_web_svcs/sosgui.log ; do
#	if [ ! -f $file ]; then
#		touch $file
#		chown apache:apache $file
#	fi
#done
for file in httpd.conf httpd-wsgi.conf settings.py db.sqlite3 ; do
	if [ ! -f /config/$file ]; then
        cp /custom/$file /config/
	fi
done

#if [ ! -d /config/etc/ ]; then
#	mkdir -p /config/etc
#fi

#for file in passwd passwd- group ; do
#	if [ ! -f /config/etc/$file ]; then
#        cp /custom/$file /config/etc/
#	fi
#done
#		chown apache:apache /config/db.sqlite3
#if [ ! -z "$apacheUID" ] && [ ! -f /config/etc/initialized ]; then
#	usermod -u $apacheUID apache
#fi
#if [ ! -z "$apacheGID" ] && [ ! -f /config/etc/initialized ]; then
#	groupmod -g $apacheGID apache
#fi

#if [ ! -f /config/etc/initialized ]; then
#	find /run /var /config/db.sqlite3 /custom -uid 48 |xargs chown apache:apache
#	touch /config/etc/initialized
#fi

/usr/sbin/httpd -D FOREGROUND

