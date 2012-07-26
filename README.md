README file for Diggy Show Digger


Diggy is a one file solution for automating TV show downloads for users with an NZBMatrix account using SabNZBd.


Why Diggy?
Good question. There are plenty of auto show downloaders at the moment. Most of them are far superior to this script. The main
reason for this script is for running on very old, embedded, headless (or other) environments. For example, satellite receivers,
phones, very old PCs, STB etc. It is completely command line driven and requires little configuration and/or dependencies*
    

What does it do?
- Diggy will get you TV shows for you. The workflow is like this:
- Configure Diggy with your NZBMatrix details (username, API key) and SabNZBd deatail (IP, port API key)
- Configure Diggy with your favorites shows
- Diggy connects to the internet and pulls down all the show/season/episode information to its local database
- Configure each show and tell Diggy which seaons/episodes you have (or have not) watched
- Digger it!
- Diggy scans your database and builds a list of shows you need, it will then search NZBMatrix and build a list of nzb files
needed before sending this list to your local SabnNZBd server where it can download your shows
- Once you're configured add diggy to your crontab and forget about it


Install details.

Dependencies:
perl
DBD::SQLite
JSON::XS

For Debian / Ubuntu install from packages
- sudo apt-get install libdbd-sqlite3-perl
- sudo apt-get install libjson-xs-perl
- sudo apt-get install libwww-perl 
- sudo apt-get install libcrypt-ssleay-perl

Failing that use CPAN (not recommmended)
- cpan install JSON::XS
- cpan install DBD::SQLite
- cpan install LWP::Simple

Windows: Not tested but may work!

Usage:

To run the application e.g. to set up the config, add/remove shows, build you database etc:

- perl digger.pl

This will present you with the interface where you can configure your setup
- NOTE: On first run you will be prompted to setup your API/Server config.

To run on a crontab edit the digger.pl file and change the $diggy_path at the top of the file to point to your base directory.
The in your crontab run "digger.pl getshows". You can test this at the command line too.
