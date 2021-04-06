#!/bin/bash

source paramFile

# Using Sourced Arguments 

echo -e "\n1. Sourced Parameter"
echo -e "\nTarget Directory is $targetDirectory"
echo -e "\nProjectName is $projectName"
echo -e "\nDatabaseName is $dbName"
echo -e "\nWebURL is $webUrl"
echo -e "\nTarget Repository URL is $repositoryUrl"

# Setting up DB

echo -e "\n2. Setting up DB\n"

sudo mysql -u root -p$rootPassword -e "CREATE DATABASE $dbName;"
sudo mysql -u root -p$rootPassword -e "GRANT ALL PRIVILEGES ON $dbName. * TO '$dbUser'@'localhost';"
sudo mysql -u root -p$rootPassword -e "FLUSH PRIVILEGES;"

# Cloning base WP directory from GITHUB in Target Directory

echo -e "\n3. Cloning base Laravel repository from GITHUB in Target Directory\n"

cd $targetDirectory

git clone $repositoryUrl

cd $projectName 

# Setting up base WP 

echo -e "\n4. Copying Environment File"

mv .env.example .env

# Change the DB credentials in .env file

echo -e "\n5. Change the DB credentials in .env file"

sed -i "s/.*DB_DATABASE=.*/DB_DATABASE=$dbName/" .env
sed -i "s/.*DB_USERNAME=.*/DB_USERNAME=$dbUser/" .env
sed -i "s/.*DB_PASSWORD=.*/DB_PASSWORD=$dbPassword/" .env

echo -e "\n6. Composer Install"

composer install --quiet

echo -e "\n7. DB Migrations and Seedings"

php artisan migrate:fresh --seed

echo -e "\n8. Setup required permissions in projectDirectory"

find . -type d -exec chmod 0775 {} \;
find . -type f -exec chmod 0664 {} \;
sudo chmod -R 0777 storage/

# If need to assign TargetDirectory ownership to another user
# sudo chown -R cc:www-data $targetDirectory/$projectName

# Setting up NGINX config

echo -e "\n9. Creating a site-available config for WP setup"

echo -e "
server {

    listen 80;
    server_name $webUrl;
    root $targetDirectory/$projectName/public;
    index index.php index.html index.htm index.nginx-debian.html;

    access_log      /var/log/nginx/$webUrl.access.log;
    error_log       /var/log/nginx/$webUrl.com.error.log;

    client_max_body_size 10240M;

    add_header X-Frame-Options "SAMEORIGIN";

    location ~* \.(css|js|ico|gif|jpeg|jpg|webp|png|svg|eot|otf|woff|woff2|ttf|ogg)$ {
        expires max;
        fastcgi_hide_header Set-Cookie;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_param LARAVEL_ENV Staging;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }
        location ~ /\.ht {
        deny all;
    }
}" | sudo tee -a /etc/nginx/sites-available/$projectName

echo -e "\n10. Create symlink"

sudo ln -s /etc/nginx/sites-available/$projectName /etc/nginx/sites-enabled/$projectName

echo -e "\n11. Reload NGINX config\n"

sudo service nginx reload

echo -e "\n12. Setting up SSL using Certbot\n"
sudo certbot --nginx -n --redirect -d $webUrl
