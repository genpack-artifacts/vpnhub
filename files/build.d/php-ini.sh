set -e
sed -i 's/^max_execution_time.\+$/max_execution_time = 300/' /etc/php/apache2-php*/php.ini
sed -i 's/^max_input_time.\+$/max_input_time = 300/' /etc/php/apache2-php*/php.ini
sed -i 's/^post_max_size.\+$/post_max_size = 16M/' /etc/php/apache2-php*/php.ini
