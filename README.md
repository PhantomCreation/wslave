WSlave
======
WSlave, short for "word slave", is a WordPress control tool.  
  
*"Word Slave" is an archaic term that refers to someone being bound to [a slave to] the words of 
a contract. Since most WordPress work is usually done under contract the naming seemed 
doubly-appropriate. The name make no reference to actual slavery, and we have no particular 
intention of changing the name; but if, even after reading this explanation, you feel the name 
is inappropriate, then please suggest an alternative and we may consider changing the name.*

Details
-------
Word Slave sets up a WordPress installation in a fairly generic layout.
Basically the layout a lot of people, including "officials" in the Word Press developer community 
seem to be using combined with a sort of Rails like layout below 'public' that houses the control 
tools and configuration files. In somewhat-generally-accepted "best practice" form, the WordPress 
folder is self contained as a Git sub-module in the 'public' folder. 
Contents and themes are stored in a separate wp-content folder also in 'public'. Overrides are 
pre-set in the wpconfig.php file and a vanilla .htaccess with general settings that match the 
layout are automatically placed during installation. On deployment, wpconfig.php 
is dynamically generated. Salts are also generated during setup, and stored locally. Basically 
unless you have a very specific reason you'll never have to touch any WordPress control file; 
everything is done for you with the installed tool chain.
  
Development server functionality is provided by Docker, so you don't need to install a ○AMP 
stack on your machine. Rake tasks are provided for if you want to pull the database and files 
inserted into the installation [uploaded, attached, etc.] from the control panel within the 
development VM. Files pulled out of the VM can be set as seeds, and will be seeded to the live 
or staging site upon deployment.

Deployment is provided by Capistrano because it's basically the lowest overhead deployment tool 
and doesn't try to do things like provisioning - which is overkill as most WordPress sites are 
put up on shared hosts etc.

Requirements
============
*Short list*: ruby, git, docker with docker-compose, \*nix/POSIX compliant terminal/shell.
  
*Detailed list*
1. A user who belongs to the 'www-data' group (only required to set write permissions for Docker).
2. A newer version of ruby and usable ruby gems setup. Ruby packages on some systems may not allow 
  gem installation. We generally recommend RVM.
3. A properly installed Git.
4. A full Docker installation including docker-compose.
5. A working and accessable installation of PHP composer.
6. Preferably a POSIX compliant shell with standard tools such as BASH/DASH/ZSH in Linux, OS-X, 
	or MSYS2 or WSL2 in Windows.

Re: Windows
-----------
wslave is not actively maintained on Windows, but as of this writing it has been tested and runs 
in WSL2 on both Pro and non-Pro versions, or for Pro versions in MSYS2, CMD with POSIX tools 
enabled (ls, cd, mkdir, chown, chmod...), or PowerShell.  
  
Running under WSL2 is generally easier regardless of if you have a Pro version of Windows:
simply install Ruby, Docker, etc., and add your user to the www-data group (as per the standard 
Linux setup).  
  
Running under MSYS2 requires you install Ruby, PHP, etc. within MSYS2 and set your environment 
variables properly to allow docker and docker-compose to be run from within MSYS2.  
  
Running from CMD or PowerShell requires a regular Windows Ruby installations and probably some 
tweaking of your environment. This is the most complex setup as it requires a lot of system 
specific environment settings and there's a variety of issues that can arrise due to CMD and 
PowerShell not really being properly POSIX compliant / completely compatible with \*nix style 
tools. 
  
All things considered running under WSL2 is recommended as it maintains the higest compatibility 
with the lowest ammount of setting and tweaking environment variables - and it doesn't require 
a Pro version of Windows to run the container VMs.

Installation
============
In a terminal:
```sh
gem install wslave
```
Depending on how you installed Ruby/Ruby Gems you may need to do this with root privileges or 
sudo.

Usage
=====
Create a project in an empty folder:
```sh
wslave new
```
or create a new project with a name:
```sh
wslave new myblog
```
If you are going to be developing wslave, you can specify the path of your local wslave 
and this will be automatically set in the Gemfile of the generated project (*NOTE: 
this path is relative to the project, not where you are running the command*):
```sh
wslave new myblog --wspath ../wslave
```
If you are generating multiple projects, you can save on time and bandwidth by specifying 
the location of an already cloned WordPress distribution, which will copy from that location 
instead of doing a full clone from GitHub:
```sh
wslave new myblog --wppath /shared/wordpress
```
If you want to specify a specific verison of WordPress to use, you can do so like this:
```sh
wslave new myblog --version 5.2
```
  
You now have a variety of rake tasks and a pre-configured Capistrano configuration.  
First, try starting up a local development server:
```sh
wslave server start
```
This will start up 3 docker containers: one running a MariaDB instance, 
one running an Apache + PHP server instance mapped to [localhost:8000](localhost:8000), 
and one running an nginx + PHP-FPM instance mapped to [localhost:8001](localhost:8001).  
  
If you have stale containers running it's possible you'll have issues, so we made a 
flag to kill orphaned containers. Just run the server command with -f:
```sh
wslave server start -f
```
  
You can edit themes and files in public/wp-content. This folder is mounted within the 
container, so changes should be immediate as if you were running the server on your host OS. 
Edit your themes and plugins as you like, and be sure to use git to manage your sources. 
When you're done with the dev server, type this to shut it down:
```sh
wslave server stop
```
If you want to clear out all the data saved in the database/cache of the dev container type:
```sh
wslave server stop -v
```
This will reinitialize everything, and you will loose your work if you haven't backed up the 
container information locally.  
  
To back up the dev database locally, we use a rake task:
```sh
rake db:dev:backup
```
And to set this as the "active" database, which will be seeded during deployment and to new 
dev containers, type:
```sh
rake db:dev:activate
```
You can check this into your repository with git, and when another dev grabs your repository 
and starts a dev container they'll have a copy of your dev database.  
  
Now let's deploy. First off edit the following files:
 * config/database.yml
 * config/definitions.yml

Put in the databse, host, user, etc. information for your deploy target(s). If you don't 
have a staging server simply ignore those fields. Now, type:
```sh
cap production deploy:initial
```
The "deploy:initial" sub task needs to be run the first time, after that simply use "deploy" 
to update. Initial sets up some remote variables. *We'll try to make this automatic 
in the future but for now this is just how it is.*  
  
If you encountered any problems, try adjusting your configuration files. If you're being 
constantly asked for your SSH key then you need to read up on adding your public key to the 
authorized hosts on your server. Protip: This is really easy with the "ssh-copy-id" command on 
GNU/Linux.  
  
Now, if you edit your theme etc locally, simply commit your changes to git and push them to 
master of your repository host. Then type:
```sh
cap production deploy
```
and your changes will be pushed to your production server.  
  
To back up your production server, type:
```sh
cap production backup
```
This will copy all the uploaded and changed files in everything but the themes directory of 
wp-content, and will create a backup of the databse in db/production. To make that production 
databse the active database, type:
```sh
rake db:production:activate
```
Now, when you start a fresh dev container, all the files and database from the production server 
will show up within the dev container.  
  
This concludes the short guide. If there's enough interest we'll expand it or perhaps make a 
detailed video tutorial.

Cloning an Existing wslave Project
----------------------------------
Since Wordpress has specific versioning and permissions that need to be set, wslave comes with 
the `wslave sync` command to sync project files and set permissions for you. Simply run this 
command after cloning the repository and running `bundle install`. Keep in mind you will 
need a user account that is a member of the 'www-data' account on your local system if you are 
using a \*nix OS.

!WARNING!
---------
Currently there are multiple issues with depenedencies for what is currently the stable version 
(9) of Sage. Because of this, wslave defaults to using the in-development version. If you need 
to use Sage 9 we recommend you don't use the wslave shortcuts and helpers for Sage.  
※This warning will be removed when Sage 10 is officially released.

Updating
--------
wslave will update to the newest version when you run ```bundle update```. Before you update, 
you should probably make a commit to your git repository. After updating, you can update your 
files to the latest wslave version by running ```wslave update```

Sage Themes
-----------
wslave has integrated Sage theme helpers.

### Existing Sage Themes
If you have an extisting Sage theme you will need to 
copy the files into public/wp-content/themes/"theme name" (replacing "theme name" with the actual 
name of your theme). Then create a config file at `config/sage.yml` with the following 
content:
```yml
---
:theme: "theme name"
```
(Again, replacing "theme name" with the name of your theme). 

### New Sage Themes
You can create a new sage theme with ```wslave sage new theme_name```, repacing theme_name with 
the name of the theme you wish to create.  
**CAUTION** When/if asked ```Do you want to remove the existing VCS (.git, .svn..) history?``` 
answer **n**. Otherwise you will have to re-add all the wslave project files to git. We have no 
idea why Sage does this...

### Updating/Installing Packages
You can of course work directly with yarn/composer in your theme directory, or use 
```wslave sage update```.

### Building Theme Files
You can of course work directly with yarn/composer in your theme directory, or use 
```wslave sage build```

### Produciton Build and Deployment
For static deployment we don't want to commit the vendor and dist directories to SCM, so there's 
an extra task in Capistrano that's been added to do this for us if you're using the wslave 
deployment chain. The command to do this would be ```cap staging deploy:sage``` or 
```cap production deploy:sage``` for staging or production respectively.  
  
To do a production build without Capistrano simply use ```wslave sage production``` and assets 
will be compiled and placed in the appropriate locations in your theme directory.

Porting an Existing WordPress Installation to wslave
----------------------------------------------------
As long as you have some basic tools you can quickly port most WordPress installations into 
a wslave managed project fairly easily. Specifically, you'll need the `wp-content` folder and 
a dump file of the database (of a specific format, NOT the "Database Backup" you get from some 
web-based management consoles).  
  
*NOTE: You will need SSH shell access to the server currently hosting the site. You will need to 
	have your SSH public key registered on the server to smoothly perform any automatic 
	operations/perform Capistrano tasks.*
  
The general steps to migrate an existing WordPress installation are:
1. Create a new wslave project with `wslave new my-project-name`.
2. Obtain the `wp-content` folder, either with a tool like rsync, sftp, scp, or even just ftp. 
	If you are only obtaining a theme from the wp-content folder you only need to copy that theme 
	into the wslave generated `public/wp-content/themes` folder, but if you have uploads / 
	specific plugins / customized language files / etc. you'll need to either merge the 
	`wp-content` folder from your existing project with the `public/wp-content` folder generated 
	by wslave, or remove the `public/wp-content` folder generated by wslave and copy the 
	`wp-content` folder into `public/` to replace the wslave generated version.
3. Obtain a databse dump from the running site. You can do this manually, or attempt to let 
	wslave do it for you.
	* Automatic Method:
		1. Edit the `config/definitions.yml` and `config/database.yml` files and fill in all
			details for the "production" profile to reflect the details of the currently running 
			site. Specifically the `user`, `production` information under `host` in `definitions.yml`,
			and the `username`, `password`, `host`, and `databse` name for `production` in 
			`database.yml`. *HINT: You can find database login information in the `wp-config.php` file 
			in the public root of the WordPress installation on the server.*
		2. Run `cap production db:backup`. This create a snapshot dump of the database and copy it to 
			`db/production/wordpress.sql`.
		3. Make the dump you just obtained the active database by running `rake db:production:activate`.
		4. Be sure to alter any settings you've made to `config/definitions.yml` and 
			`config/database.yml` which will not be used for your future production deployment. If 
			your web server or database details will be different when you re-deploy the site in the 
			future you should change these now as to not accidentally deploy over the running site.
	* Manual Method: You will need to obtain a snapshot dump of your running database either with the 
		`mysqldump` tool or in a way that dumps the database into a compatible .sql format. Usually 
		this would be done with a command like: 
		`mysqldump --opt --user=USERNAME --password=PASSWORD --host=HOST DATABASENAME > wordpress.sql` 
		replacing the all-caps values with the appropriate values for your database. Then, you can copy 
		this file to `db/active/wordpress.sql` in the wslave managed project you've created.
  
If you do not have shell access this whole process will be quite different. You'll probably need to 
obtain the wordpress files either through plain FTP or through a proprietary tool, and you may need to 
create a backup of the WordPress database using an internal tool or plugin and then re-import it into 
your new wslave managed project by starting a development server and using the same internal tool or 
plugin to import the database information.  
  
As each server and setup are different, and there are many "managed" services for WordPress which have 
specific restirctions, this process could be very different for you and the above guide should only be 
considered a generic example.

Notes on Apache
---------------
The provided configuration aims to support as many configurations as possible. At the moment .htaccess 
is provided by the wslave base files and wp-config.php is automatically generated both during the 
configuration and deployment processes. Currently there is no way to override this, and running wslave 
update or deploying will end up overwriting these files. Up until now we haven't found any instance of 
having to override this, but we expect there is need to do so, so please submit an issue with what and 
how you're trying to modify so we can plan and implement such functionality.  
  
### .htaccess
The .htaccess file provided has directives which do the following:
 * Silently redirects the site apex to the wordpress index.php file.
 * [※New] Redirects the wp-admin pages to wordpress/wp-admin. (Newer versions of WP do -not- route 
  through the main index, so this redirect was required.)
 * Disallowes direct access to files. ※This is a generally recommended security measure.
 * Forwards URL paths that do not resolve back to the main index.
 * Provides anchor points for WP extensions to insert their own directives 
  (be cautious when re-deploying or updating from wslave).
 * Disables the file/post upload limits imposed by PHP (file and upload limits are regulated by the 
  web server).

Notes on nginx
--------------
While WordPress is generally run on Apache, the truth is it can be run on nginx with PHP-FPM, and it 
runs very quickly, cleanly, and securely when configured properly. We've done our best to provide an 
auto-generated nginx vhost configuration file, but as nginx does't scatter its configuration across 
multiple local files [such as .htaccess] combined with a main configuration it's very likely you'll 
need to customize this file - so please consider the provided file only a reference and be sure to 
review it before using it in a deployed configuration. If you have any recommendations as to how we 
could improve the nginx configuration file template please submit an issue or a PR!

For more help
-------------
Try the following commands:
```sh
wslave --help
```
```sh
rake -T
```
```sh
cap production -T
```

Caution
=======
1. Even though Capistrano is bening used for deployment, many files such as the wordpress 
  installation and Sage static build (production) files are not committed. Other files are 
  generated dynamically. Because of this, some files are deployed that are not/never included 
  in the git repository, and you should be careful that your repository and local development 
  files appropriately match. This also, unforunately, can make automated deployments somewhat 
  complicated.
2. URL replacement: WordPress doesn't use relative paths and hard-codes URLs in the database 
  (which is a terrible way to manage URLs and should be refactored in WP core...). Because of 
  this we need to replace URL entries depending on where we are running the site. During 
  development this is localhost:8000, so all the Staging and Production URLs get changed to 
  localhost:8000, and then these localhost:8000 entries are converted to production or staging 
  URLs on deployment. If you have an article or something that explicitly used localhost:8000 
  this would end up getting changed to the production or staging URL during deployment.
3. Sage version: Due to Sage v9 being massively outdated, wslave Sage theme creation currently 
  defaults to the upstream dev version (Sage 10 beta). If you would like to use version 9, 
  please create the theme manually with composer and add the "sage.yml" file as described above 
  in the Sage Theme section.
4. Permissions: When working on themes or extensions you may encounter many permission issues 
  with files not being read due to them not being owned by the www-data group. You may have to 
  periodically run ```wslave sync``` or manually chown files (EG: ```chown -R :www-data ./``` 
  in the directory you are working in).

Known Issues
============
There are a few known issues which can't really be fixed by the wslave package. While we can't 
provide support for any of these (please don't report system specific issues not directly related 
to wslave) here are some notes on common problems we've dealt with and what solutions we've found.

PHP 8
-----
At the time of this update WordPress and most extensions do *not* function properly and you will 
essentially need to be running a PHP version in the 7 series. The problem being here that on some 
operating system versions and package managers the default for PHP has already been raised to 8, 
and as PHP doesn't have language backward-compatibility modes you may need to either supply your 
build of PHP/PHP-FPM. If you're using a compatible OS we recommend phpenv with php-build. The 
phpenv repository with install instructions for phpenv and php-build can be found 
[here](https://github.com/phpenv/phpenv).

gyp
---
One of the requirements for a variety of node packages used in Sage theme development and in 
various other JavaScript/node based tools is gyp [node-gyp], which is notorious for 
having installation issues which will break a lot of setup scripts and can cause issues. If you 
encounter an issue during a gyp installation we've found the following commands seem to fix it 
fairly often (*YMMV):
```
npm install --global node-gyp@latest
npm config set node_gyp $(npm prefix -g)/lib/node_modules/node-gyp/bin/node-gyp.js
```

wp-admin Forwards to HTTPS even on localhost
--------------------------------------------
Newer versions of WordPress have embedded forwards to HTTPS for wp-admin and login pages. While 
you can attempt to diffuse these this doesn't always work, and you may experience a forward to 
port 443 or to https:// even when you're working on a local wslave development server. We have 
attempted to prevent this but different browsers and the Apache container at :8000 and the nginx 
container at :8001 all behave differently and you are likely to encounter this issue. Simply 
fixing your wp-admin url to something like http://localhost:8001/wordpress/wp-admin after being 
forwarded should bring you to the admin login page and there should be no issues after that.  
  
Suggestions or patches to more cleanly avoid this issue would be much appreciated.

License
=======
AGPL version 3 and GPL version 3. Please contact info@phantom.industries if you want a commercial 
or closed source license.

Support
=======
If you find a bug or want to add an improvement we strongly recommend you provide a patch and a 
Pull Request. This project came from a need for a very specific tool, and as long as that tool 
fulfills our needs there's no incentive for us to add extra features or improvements; but we will 
check Pull Requests and merge what looks good. If you'd like to fund development of a specific 
feature we'll include you as a sponsor.
