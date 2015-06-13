Poietic Generator
=================

Installation
------------

### Requirements

First, make sure you have a proper git, ruby & rubygems installation on your system.

If not, install them with :

    $ sudo apt-get install git-core ruby ruby-dev  

Then checkout the sources from the public repository :

    $ git clone https://github.com/Gnuside/poietic-generator.git


### Setup

We strongly recommand using a ruby environment wrapper like rbenv.

If not, you can try installing bundler with:

    $ gem install bundle

Then, install  headers packages required to build some gems :

    $ sudo apt-get install make libmysqlclient-dev libsqlite3-dev g++

Finally, from the project directory, run the following command to install
locally into the "vendor/bundle" directory the gems required by this project
and all their dependencies :

    $ bundle install


### Configuration

Copy config/config.ini.example to config/config.ini then edit it to your needs.

Depending on your choices, you may need to install a database system with `apache phpmyadmin mysql-server-5.5`

Create a tmp directory locally. It will be use by the devel-script to run the service.


Running the server
------------------

Simply type the following command, from the project directory :

    $ bundle exec foreman start

Command-line interface
----------------------

### Listing sessions

    $ bundle exec poietic-cli list

### Starting a new session

    $ bundle exec poietic-cli create

### Generating a video

    $ bundle exec poietic-cli sequence 10 tmp/vid1
    $ bundle exec poietic-cli video tmp/vid1 tmp/vid1.mp4 -outsize 640:-1

### Other commands

    $ bundle exec poietic-cli help
    Commands:
      poietic-cli create [-n NAME]                      # Start a new session
      poietic-cli delete (-a | ID)                      # Delete session ID
      poietic-cli finish ID                             # Finish a session
      poietic-cli help [COMMAND]                        # Describe available commands or one specific command
      poietic-cli list                                  # List all session
      poietic-cli range ID                              # Duration of session ID
      poietic-cli rename ID NEWLABEL                    # Rename a group
      poietic-cli sequence ID DIRECTORY                 # Dump a sequence of snapshots in session ID between OFFSET_START and...
      poietic-cli shapshot ID OFFSET FILENAME [FACTOR]  # Dump snapshot in session ID at OFFSET and save it in FILENAME
      poietic-cli video DIRECTORY FILENAME [-outfps v]  # Create a video from a DIRECTORY with FPS (using FFMPEG) and save it...


Contributing
------------

1. Fork it ( http://github.com/Gnuside/poietic-generator/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


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

