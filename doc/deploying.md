Deploying
=========

## Configuring the web server

Install a reverse proxy server, like nginx :

    sudo apt-get install nginx


In the directory ``/etc/nginx/sites-available/``, create a configuration file for 
a virtual host called ``poietic-generator.com``, with the following content :

    upstream poietic-generator_cluster {
        server  unix:/var/tmp/poietic-generator.sock;
    }

    server {
        listen          80;
        server_name     poietic-generator.com;
     
        access_log      /var/log/nginx/poietic-generator.access_log;
        error_log       /var/log/nginx/poietic-generator.error_log warn;
    
            root            /var/www;
            index           index.php index.html;
    
            location / {
                break;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-Proto https;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_pass http://poietic-generator_cluster;
    
                # in order to support COPY and MOVE, etc
                set  $dest  $http_destination;
                if ($http_destination ~ "^https://(.+)") {
                    set  $dest   http://$1;
                }
                proxy_set_header  Destination   $dest;
            }
    }


The web server will then redirect any external request to internal unix
socket ``/var/tmp/poietic-generator.sock`` .

Enable the configuration :

    ln -s /etc/nginx/sites-available/poietic-generator.com \
        /etc/nginx/sites-enabled/poietic-generator.com


Restart nginx :

    /etc/init.d/nginx restart

