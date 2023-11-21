
# How to Install ModSecurity 3, OWASP CRS with Nginx on Ubuntu 22.04 or 20.04

## Step 1: Update Ubuntu Before Modsecurity 3 Installation
The first step towards a secure and efficient server is keeping it up-to-date. This ensures all software packages have the latest security patches and performance improvements. Execute the following command to update your system:
 ```console
sudo apt update && sudo apt upgrade 
 ```
This command first updates the package lists for upgrades (sudo apt update).

## Step 2: Remove Pre-existing Nginx Installation (Situational)
If you have a pre-existing Nginx installation, we recommend removing it and installing the latest version from a custom PPA maintained by Ondřej Surý. This version has additional dynamic modules, such as the Brotli module, for improved compression.

First, stop the current Nginx service with the following:
 ```console
sudo systemctl stop nginx
 ```
Then, remove the existing Nginx installation with the following commands:
 ```console
sudo apt purge nginx -y && sudo apt autoremove nginx -y
 ```
Here, the purge option completely removes the Nginx package and its configuration files. The autoremove command removes any packages that were automatically installed to satisfy Nginx’s dependencies but are no longer needed.

## Step 3: Add the Latest Nginx PPA (Optional)
Remove the outdated Nginx service, then add a new, current PPA (Personal Package Archive) for Nginx. Choose between a stable or mainline version; opt for the mainline version to access the latest features and improvements.

To add the stable PPA, execute:
 ```console
sudo add-apt-repository ppa:ondrej/nginx-stable -y
 ```
Or for the mainline PPA, use:
 ```console
sudo add-apt-repository ppa:ondrej/nginx-mainline -y
 ```
## Step 4: Update Packages Index After Nginx PPA Import on Ubuntu
After importing the desired repository, updating your APT sources list is necessary. This ensures the system knows about the new packages in the added repository. Update your sources list with the following:
 ```console
sudo apt update
 ```
Now, install Nginx with the following command:
 ```console
sudo apt install nginx
 ```
During the installation, you may be prompted to keep or replace your existing /etc/nginx/nginx.conf configuration file. It’s generally recommended to keep your current configuration file by pressing n.

## Step 5: Uncomment DEB-SRC Nginx Source on Ubuntu
The PPA installation process does not include the Nginx source code by default. You must enable a specific feature and manually download the Nginx source code to compile Modsecurity later in this tutorial.

Open the configuration file located in /etc/apt/sources.list.d:
 ```console
sudo nano /etc/apt/sources.list.d/ondrej-ubuntu-nginx-mainline-*.list
 ```
Find the line that starts with # deb-src and uncomment it (i.e., remove the #). If you use a different third-party repository, replace the path in the command with the appropriate one:
# deb-src http://ppa.launchpad.net/ondrej/nginx-mainline/ubuntu/ jammy main

Once done, save the file by pressing CTRL+O and then exit by pressing CTRL+X.

If you’re more comfortable with command-line utilities, you can also use the sed command to uncomment the source line:
```console
sudo sed -i 's/# deb-src/deb-src/g' /etc/apt/sources.list.d/ondrej-ubuntu-nginx-mainline-*.list
```
Finally, update the repository list using the following command:
```console
sudo apt update
```

# Securing Nginx With ModSecurity
## Securing Nginx With ModSecurity

## What is ModSecurity?
- ModSecurity is a free and open source web application that started out as an Apache module and grew to a fully-fledged web application firewall. It works by inspecting requests sent to the web server in real time against a predefined rule set, preventing typical web application attacks like XSS and SQL Injection.

- While originally an Apache module, ModSecurity can also be installed on Nginx as detailed in this guide.

## Prerequisites & Requirements
In order to install and configure ModSecurity, you need to have a Linux server with the following services running:

	Nginx
For instructions, see our guide on How to Install NGINX on Ubuntu 18.04 LTS. Installation instructions for several other Linux distributions are also accessible from this guide.

## Note
This demonstration has been performed on Ubuntu 18.04. However, all techniques demonstrated are distribution agnostic with the exception of package names and package managers.


# Downloading & Building ModSecurity
- While ModSecurity is not officially supported as a module for Nginx, a workaround exists involving the ModSecurity-nginx connector. The ModSecurity-nginx connector is the connection point between Nginx and libmodsecurity (ModSecurity v3). Said another way, the ModSecurity-nginx connector provides a communication channel between Nginx and libmodsecurity.

- The ModSecurity-nginx connector takes the form of an Nginx module that provides a layer of communication between Nginx and ModSecurity.

- To begin the installation process, follow the steps outlined below:

- 1: Install all the dependencies required for the build and compilation process with the following command:


 ```console  
 sudo apt-get install bison build-essential ca-certificates curl dh-autoreconf doxygen \
  flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \
  libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales \
  lua5.3-dev pkg-config wget zlib1g-dev zlibc libxslt libgd-dev
 ```
 - 2: Ensure that git is installed:
 ```console  
 sudo apt install git
 ```
- 3: Clone the ModSecurity Github repository from the /opt directory:
 ```console 
cd /opt && sudo git clone https://github.com/SpiderLabs/ModSecurity
 ```

- 4: Change your directory to the ModSecurity directory:
 ```console
cd ModSecurity
 ```
- 5: Run the following git commands to initialize and update the submodule:
 ```console
sudo git submodule init
sudo git submodule update
 ```

 - 6: Run the configure file, which is responsible for getting all the dependencies for the build process:
 ```console
 sudo ./configure
  ```
 - 8: Run the make command to build ModSecurity:
 ```console
 sudo make
  ```
- 7: After the build process is complete, install ModSecurity by running the following command:
 ```console
sudo make install
  ```
## Downloading ModSecurity-Nginx Connector
- Before compiling the ModSecurity module, clone the Nginx-connector from the /opt directory:
 ```console
cd /opt && sudo git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
  ```

Building the ModSecurity Module For Nginx
You can now build the ModSecurity module from a downloaded copy of your Nginx version by following the steps outlined below:

Enumerate the version of Nginx you have installed:
 ```console
nginx -v
 ```
For example, the following output shows that Nginx version 1.14.0 is installed on the system:

nginx version: nginx/1.14.0 (Ubuntu)
In each of the following commands, replace 1.14.0 with your version of Nginx.

Download the exact version of Nginx running on your system into the /opt directory:
 ```console
cd /opt && sudo wget http://nginx.org/download/nginx-1.14.0.tar.gz
 ```
Extract the tarball:
 ```console
sudo tar -xvzmf nginx-1.14.0.tar.gz
 ```
Change your directory to the tarball directory you just extracted:
 ```console
 cd nginx-1.14.0
  ```
Display the configure arguments used for your version of Nginx:
 ```console
nginx -V
 ```
Here is an example output for Nginx 1.14.0:

nginx version: nginx/1.14.0 (Ubuntu)
built with OpenSSL 1.1.1  11 Sep 2018
TLS SNI support enabled
configure arguments: --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-GkiujU/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module
To compile the Modsecurity module, copy all of the arguments following configure arguments: from your output of the above command and paste them in place of <Configure Arguments> in the following command:
 ```console
sudo ./configure --add-dynamic-module=../ModSecurity-nginx <Configure Arguments>
 ```
Build the modules with the following command:
 ```console
sudo make modules
 ```
Create a directory for the Modsecurity module in your system’s Nginx configuration folder:
 ```console
sudo mkdir /etc/nginx/modules
 ```
Copy the compiled Modsecurity module into your Nginx configuration folder:
 ```console
sudo cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
 ```
Loading the ModSecurity Module in Nginx
Open the /etc/nginx/nginx.conf file with a text editor such a vim and add the following line:

load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;
Here is an example portion of an Nginx configuration file that includes the above line:

File: /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;
Setting Up OWASP-CRS
The OWASP ModSecurity Core Rule Set (CRS) is a set of generic attack detection rules for use with ModSecurity or compatible web application firewalls. The CRS aims to protect web applications from a wide range of attacks, including the OWASP Top Ten, with a minimum of false alerts. The CRS provides protection against many common attack categories, including SQL Injection, Cross Site Scripting, and Local File Inclusion.
To set up the OWASP-CRS, follow the procedures outlined below.
First, delete the current rule set that comes prepackaged with ModSecurity by running the following command:
 ```console
sudo rm -rf /usr/share/modsecurity-crs
 ```
Clone the OWASP-CRS GitHub repository into the /usr/share/modsecurity-crs directory:
 ```console
sudo git clone https://github.com/coreruleset/coreruleset /usr/local/modsecurity-crs
 ```
Rename the crs-setup.conf.example to crs-setup.conf:
 ```console
sudo mv /usr/local/modsecurity-crs/crs-setup.conf.example /usr/local/modsecurity-crs/crs-setup.conf
 ```
Rename the default request exclusion rule file:
 ```console
sudo mv /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
 ```
You should now have the OWASP-CRS set up and ready to be used in your Nginx configuration.

Configuring Modsecurity
ModSecurity is a firewall and therefore requires rules to function. This section shows you how to implement the OWASP Core Rule Set. First, you must prepare the ModSecurity configuration file.

Start by creating a ModSecurity directory in the /etc/nginx/ directory:
 ```console
sudo mkdir -p /etc/nginx/modsec
 ```
Copy over the unicode mapping file and the ModSecurity configuration file from your cloned ModSecurity GitHub repository:
 ```console
sudo cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec
sudo cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
 ```
Remove the .recommended extension from the ModSecurity configuration filename with the following command:
 ```console
 sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
 ```
With a text editor such as vim, open /etc/modsecurity/modsecurity.conf and change the value for SecRuleEngine to On:


File: /etc/modsecurity/modsecurity.conf
# -- Rule engine initialization ----------------------------------------------

# Enable ModSecurity, attaching it to every transaction. Use detection
# only to start with, because that minimises the chances of post-installation
# disruption.
#
SecRuleEngine On
...
Create a new configuration file called main.conf under the /etc/nginx/modsec directory:
 ```console
sudo touch /etc/nginx/modsec/main.conf
 ```
Open /etc/nginx/modsec/main.conf with a text editor such as vim and specify the rules and the Modsecurity configuration file for Nginx by inserting following lines:


File: /etc/modsecurity/modsecurity.conf
 ```console
Include /etc/nginx/modsec/modsecurity.conf
Include /usr/local/modsecurity-crs/crs-setup.conf
Include /usr/local/modsecurity-crs/rules/*.conf
 ```
Configuring Nginx
Now that you have configured ModSecurity to work with Nginx, you must enable ModSecurity in your site configuration file.

Open the /etc/nginx/sites-available/default with a text editor such as vim and insert the following lines in your server block:
 ```console
modsecurity on;
modsecurity_rules_file /etc/nginx/modsec/main.conf;
Here is an example configuration file that includes the above lines:


File: /etc/nginx/sites-available/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/main.conf;

        index index.html index.htm index.nginx-debian.html;

        server_name _;
        location / {
                try_files $uri $uri/ =404;
        }
}
 ```
Restart the nginx service to apply the configuration:
 ```console
sudo systemctl restart nginx
 ```
Testing ModSecurity
Test ModSecurity by performing a simple local file inclusion attack by running the following command:
 ```console
curl http://<SERVER-IP/DOMAIN>/index.html?exec=/bin/bash
 ```
If ModSecurity has been configured correctly and is actively blocking attacks, the following error is returned:

 ```console
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.14.0 (Ubuntu)</center>
</body>
</html>
 ```