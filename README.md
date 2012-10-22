PollenGrain - Timelines. Quick. Easy.
=====================================
Create and Share timelines
--------------------------
 
1. git clone git@github.com:chetanvaity/kaal.git
1. mysql -u root -p
   	 >> create database <dbname>;
	 >> grant all privileges on <dbname>.* to <dbuser>@localhost identified by '<dbpasssword>';
1. Edit config/database.yml
1. rake db:setup (Don't run migrations)
1. rails server thin
