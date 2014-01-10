Poietic Generator Reloaded
==========================

Requirements
------------

First, make sure you have a proper git, ruby & rubygems installation on your system.
If not, install them with :

    sudo apt-get install git-core ruby1.9.1 ruby1.9.1-dev  

Then checkout the sources from the public repository :

    git clone https://github.com/Gnuside/poietic-generator.git

Installation
------------

We strongly recommand using a ruby environment wrapper like rbenv.

If not, you can try installing bundler with:

    gem install bundle

Then, install  headers packages required to build some gems

    sudo apt-get install make libmysqlclient-dev libsqlite3-dev g++

Finally, from the project directory, run the following command to install
locally into the "vendor/bundle" directory the gems required by this project
and all their dependencies :

    bundle install --path vendor/bundle


Configuration
-------------

Copy config/config.ini.example to config/config.ini then edit it to your needs.

Depending on your choices, you may need to install a database system with `apache phpmyadmin mysql-server-5.5`


Create a tmp directory locally. It will be use by the devel-script to run the service.


Running
-------

### Production mode

FIXME: 


### Development mode

Simply type the following command, from the project directory :

    ./devel-run.sh


Deploying
---------

### Configuring the web server

Install a reverse proxy server, like nginx :


    sudo apt-get install nginx

In the directory "/etc/nginx/sites-available/", create a configuration file for 
a virtual host called "poietic-generator.com", with the following content :

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
socket `/var/tmp/poietic-generator.sock` .

Enable the configuration :


    ln -s /etc/nginx/sites-available/poietic-generator.com \
        /etc/nginx/sites-enabled/poietic-generator.com

Restart nginx :


    /etc/init.d/nginx restart


Credits
-------

![Gnuside](http://www.gnuside.com/wp-content/themes/gnuside-ignition-0.2-1-g0d0a5ed/images/logo-whitebg-128.png)

Got questions? Need help? Tweet at [@gnuside](http://twitter.com/gnuside).

Poietic Generator Reloaded is maintained by [Gnuside, inc](http://gnuside.com)

Original concept & funding by [Olivier Auber](http://twitter.com/OlivierAuber)


License
-------

Poietic Generator Reloaded is Copyright © 2011-2013 Gnuside.
It is free software, and may be redistributed under the terms specified in the LICENSE file.

