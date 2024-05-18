WSlave on Windows
-----------------
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
