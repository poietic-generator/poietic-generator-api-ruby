Poietic Generator
=================

Requirements
------------

First, make sure you have a proper git, ruby & rubygems installation on your system.

If not, install them with :

    sudo apt-get install git-core ruby ruby-dev  

Then checkout the sources from the public repository :

    git clone https://github.com/Gnuside/poietic-generator.git


Installation
------------

We strongly recommand using a ruby environment wrapper like rbenv.

If not, you can try installing bundler with:

    gem install bundle

Then, install  headers packages required to build some gems :

    sudo apt-get install make libmysqlclient-dev libsqlite3-dev g++

Finally, from the project directory, run the following command to install
locally into the "vendor/bundle" directory the gems required by this project
and all their dependencies :

    bundle install


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

    bundle exec foreman start

Starting a new session
----------------------

    bundle exec ./bin/poietic-cli create

Generating a video
------------------

    bundle exec ./bin/poietic-cli sequence 10 tmp/vid1
    bundle exec ./bin/poietic-cli video tmp/vid1 tmp/vid1.mp4 -outsize 640:-1

Contributing
------------

1. Fork it ( http://github.com/Gnuside/poietic-generator/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


Credits
-------

Got questions? Need help? Tweet at [@glenux](http://twitter.com/glenux).

Contributors :

 * Original concept & funding by [Olivier Auber](http://twitter.com/OlivierAuber)
 * Initial ruby development by [GNUSIDE SAS](http://twitter.com/gnuside)
 * Project is now maintained by [Glenn Y. Rolland](http://github.com/glenux)

License
-------

Poietic Generator Reloaded is Copyright © 2011-2013 Gnuside.
It is free software, and may be redistributed under the terms specified in the LICENSE file.

