WSlave
======
WSlave, short for "word slave" is a WordPress control tool.

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
  
Development server functionality is provided by Docker, so you don't need to install a ○amp 
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
0. A user who belongs to the 'www-data' group (only required to set write permissions for Docker).
1. A newer version of ruby and usable ruby gems setup. Ruby packages on some systems may not allow 
  gem installation. We generally recommend RVM.
2. A properly installed Git.
3. A full Docker installation including docker-compose.
4. A working and accessable installation of PHP composer.
5. A POSIX compliant terminal/shell. For example the "Docker Quickstart Terminal" will work fine 
  in Windows. Pretty much anything will work in Linux or OSX.

Re: Windows
-----------
If you have all of the above set up correctly there should be no issue in getting this to work. 
On a Linux installation this should only take a few minutes to set up properly, but Windows can 
be excessively difficult to set up correctly. You basically can't use the standard CMD shell, and 
power shell seems intent on completely breaking any \*nix style tool you install in very subtle 
ways if it will run them at all. A lot of Git installations will come bundled with a "Git Bash" 
which works as long as you have your path set up properly for Ruby and Docker, but there seems 
to be some Docker specific initialization that gets run by the Docker Quick Start Terminal on 
non Pro installations of Windows. So, generally, if you have Windows 10 Pro, probably use 
Git Bash, and if you have any other version of Windows use the Docker Quick Start Terminal.

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

You now have a variety of rake tasks and a pre-configured Capistrano configuration.  
First, try starting up a local development server:
```sh
wslave server start
```
This will start up a docker container running your site in localhost:8000 (or whatever IP your 
host was given if you are running with the Docker installation on Windows that 
uses a separate VM architecture. The IP will be shown toward the top when you start a 
"Docker Quickstart Terminal").  
  
If you have stale containers running it's possible you'll have issues, so we made a 
flag to kill orphaned containers. Just run the server command with -f:
```sh
wslave server start -f
```
  
You can edit themes and files in public/wp-content. This folder is mounted within the 
container, so changes should be immediate as if you were running the server on your host OS. 
Edit your themes and plugins as you like, and be sure to use git to manage your sources. 
When you're done with the dev server type this to shut it down:
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

Cloning an Existing Project
---------------------------
Since Wordpress has specific versioning and permissions that need to be set, wslave comes with 
the ```wslave sync``` command to sync project files and set permissions for you. Simply run this 
command after cloning the repository and running ```bundle install``. Keep in mind you will 
need a user account that is a member of the 'www-data' account on your local system if you are 
using a \*nix OS.

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
name of your theme). Then create a config file at ```config/sage.yml``` with the following 
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

For more help
-------------
Try the following commands:
```sh
wslave --help
```
```
rake -T
```
```
cap production -T
```

Caution
=======
1. URL replacement: WordPress doesn't use relative paths and hard-codes URLs in the database 
  (which is a terrible way to manage URLs and should be refactored in WP core...). Because of 
  this we need to replace URL entries depending on where we are running the site. During 
  development this is localhost:8000, so all the Staging and Production URLs get changed to 
  localhost:8000, and then these localhost:8000 entries are converted to production or staging 
  URLs on deployment. If you have an article or something that explicitly used localhost:8000 
  this would end up getting changed to the production or staging URL during deployment.
2. Sage version: Due to Sage v9 being massively outdated, wslave Sage theme creation currently 
  defaults to the upstream dev version (Sage 10 beta). If you would like to use version 9, 
  please create the theme manually with composer and add the "sage.yml" file as described above 
  in the Sage Theme section.

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
