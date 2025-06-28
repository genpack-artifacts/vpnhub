set -e
sed -i 's/^APACHE2_OPTS=\(.*\)"$/APACHE2_OPTS=\1 -D PHP"/' /etc/conf.d/apache2
