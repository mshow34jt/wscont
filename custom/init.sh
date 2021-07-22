set -x 
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/local/sos/bin:$PATH
export PYTHONPATH=/usr/local/sos/lib/python3.6/site-packages
if [ ! -z "$apacheUID" ] && [ ! -f /custom/initialized ]; then
	usermod -u $apacheUID apache
	if [ ! -z "$apacheGID" ]; then
		groupmod -g $apacheGID apache
	fi
	find / -uid 48 |grep -v ^/proc |xargs chown apache:apache
fi

for file in /var/log/ovis_web_svcs/settings.log /var/log/ovis_web_svcs/sosgui.log ; do
	if [ ! -f $file ]; then
		touch $file
		chown apache:apache $file
	fi
done
if [ ! -f /config/httpd-wsgi.conf ]; then
	# init or reset
	if [ -L /etc/httpd/conf.d/wsgi.conf ]; then
		# reset
		cp /custom/httpd-wsgi.conf /config
	else
		# init
		cp /custom/httpd-wsgi.conf /config
		ln -s /config/httpd-wsgi.conf /etc/httpd/conf.d/wsgi.conf
	fi
fi

if [ ! -f /config/settings.py ]; then
        # init or reset
        if [ -L /var/www/ovis_web_svcs/sosgui/settings.py ]; then
                # reset
                cp /custom/settings.py /config
        else
                # init
                cp /custom/settings.py /config
                ln -s /config/settings.py /var/www/ovis_web_svcs/sosgui/settings.py
        fi
fi

if [ ! -L /var/www/ovis_web_svcs/db.sqlite3 ]; then
	# init
	python3 manage.py migrate && \
	python3 manage.py migrate --run-syncdb && \
	echo "from sosdb_auth.models import SosdbUser; SosdbUser.objects.create_superuser('admin', 'admin@example.com', 'pass')" | python3 manage.py shell && \
	python3 manage.py collectstatic
	cp /var/www/ovis_web_svcs/db.sqlite3 /custom/db.sqlite3.firstrun
	mv /var/www/ovis_web_svcs/db.sqlite3 /config/db.sqlite3
	ln -s /config/db.sqlite3 /var/www/ovis_web_svcs/db.sqlite3
	chown apache:apache /config/db.sqlite3
else
	# reset
	if [ ! -f /config/db.sqlite3 ]; then
		cp /custom/db.sqlite3.firstrun /config/db.sqlite3
		chown apache:apache /config/db.sqlite3
	fi	
fi
if [ ! -f /custom/initialized ]; then
	touch /custom/initialized
fi

/usr/sbin/httpd -D FOREGROUND

