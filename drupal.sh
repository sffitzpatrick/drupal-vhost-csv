#!/bin/bash

# config
csvfile=example.csv                   # file with data
apachesrv=apache2                     # apache service name
vhostdir=/etc/apache2/conf.d/course   # virtual host directory
topdir=/home/drupal/sites             # html parent directory
domain=ecourse.lishost.org            # domain
dbuser=	                              # user for creating DB
dbpass=			                      # pass for creating DB
dbprivuser=		                      # user granted privs on DB
dbprivpass=                           # pass granted privs on DB
dbhost=localhost                      # DB host
acctname=admin                        # Drupal account name
acctpass=                             # Drupal account pass

export IFS=","
mkdir -p $vhostdir

# format first,last,email
cat $csvfile | while read first last email; do
  fi=${first:0:1}
  name=$fi$last
  mkdir -p $topdir/$name
  dbname=drupal_$name

  # MySQL
  mysql -u $dbuser -p$dbpass -e "CREATE DATABASE IF NOT EXISTS $dbname"
  mysql -u $dbuser -p$dbpass -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbprivus
er'@'$dbhost' IDENTIFIED BY '$dbprivpass'"

  # Drupal
  cd $topdir/$name/
  drush dl drupal
  mv $topdir/$name/drupal-7.23 $topdir/$name/html
  cd $topdir/$name/html
  drush site-install standard --db-url=mysql://$dbprivuser:$dbprivpass@$dbhost/$dbname --account-name=$acctname --account-pass=$acctpass --account-mail=$email --site-name="$name's site" -y
  drush dl calendar  ctools  google_analytics  imce  link  nice_menus   views_accordion  wysiwyg backup_migrate  date  imageapi   imce_wysiwyg   views webform panels biblio

  #ckeditor
  mkdir $topdir/$name/html/sites/all/libraries
  cp -rf /root/ckeditor $topdir/$name/html/sites/all/libraries

  #private dir
  mkdir $topdir/$name/html/sites/default/private

  #directory permissions
  chown -R www-data $topdir/$name/html/sites
  chmod -R 775  $topdir/$name/html/sites

  # Virtual Host
  cat <<EOF > $vhostdir/$name.$domain
<VirtualHost *:80>
DocumentRoot $topdir/$name/html
ServerName $name.$domain

        <Directory $topdir/$name/html>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
done

sudo service $apachesrv graceful