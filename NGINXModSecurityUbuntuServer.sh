#!/bin/bash 
# Cấu hình Log
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
logname=`basename "$0"`
logname+=".log"
logfile=$scriptdir/$logname
touch "$logfile"

# Functions
logger(){
    echo "$(date): $@" >> $logfile
    echo "## $@"
}
logger "Starting script"

# Thay đổi cấu hình NeedRestart.
sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf

# Kiểm tra bộ nhớ RAM còn trống.
swapen=0
if [ $(awk '/^MemAvailable:/ { print $2; }' /proc/meminfo) -lt 500000 ]; then	
    dd if=/dev/zero of=/swapfile bs=1024 count=512000
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	swapen=1
fi

# Step 1 - Biên dịch libmodsecurity.
apt-get update
apt-get install g++ flex bison curl doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev make -y
cd /opt/
git clone https://github.com/SpiderLabs/ModSecurity
cd ModSecurity/
git checkout -b v3/master origin/v3/master
./build.sh
git submodule init
git submodule update
./configure
make
make install 

# Step 2 - Biên dịch ModSecurity Nginx module
cd /opt/
apt-get install libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev -y
if [ -x "$(command -v nginx)" ]; then
        logger "Nginx already installed"
else
        logger "Nginx not installed. Installing..."
        apt-get install nginx -y
fi

# Xác định phiên bản Nginx đã cài đặt.
nginx_ver=$(nginx -v |& sed 's/nginx version: nginx\///' | sed 's/\s.*$//')
logger "Nginx version: $nginx_ver"

git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
wget http://nginx.org/download/nginx-$nginx_ver.tar.gz
tar zxvf nginx-$nginx_ver.tar.gz
rm nginx-$nginx_ver.tar.gz
cd nginx-$nginx_ver
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules
cd ..

# Step 3 - Thêm modsecurity vào Nginx config
sed -i 's/events {/load_module modules\/ngx_http_modsecurity_module.so;\n\nevents {/' /etc/nginx/nginx.conf

# Step 4 - Tạo ModSec config
mkdir /etc/nginx/modsec
wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
cp ModSecurity/unicode.mapping /etc/nginx/modsec

# Kiểm tra - Trước khi bật tính năng chặn ModSec, kiểm tra xem Nginx có chấp nhận tất cả các yêu cầu không.
logger "Test 1 Should return a 200 status code:"
echo "### Test 1 Should return a 200 status code:"
test=$(curl -s -H "User-Agent: nessustest" http://localhost/)
if echo "$test" | grep -q "Welcome"; then 
        logger "200 found - Web server configuration is correct. PASS"
else
        logger "No 200 found - Web server configuration incorrect. FAIL"
fi

# Step 5 - Turn SecRuleEngine On
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

# Step 6 - Add ModSec rules
## Work out latest version

# V1.1
#crs_ver=$(curl https://github.com/coreruleset/coreruleset/releases/latest | grep -o -P '(?<=tag/v).*(?=">redirected)')
crs_ver=$(curl --silent "https://api.github.com/repos/coreruleset/coreruleset/releases/latest" | grep -oP '(?<=tag/v)[^"]*')

wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v$crs_ver.tar.gz
logger "Downloaded Core Rule Set version: $crs_ver"
tar -xzvf v$crs_ver.tar.gz
rm v$crs_ver.tar.gz
mv coreruleset-$crs_ver /usr/local
cp /usr/local/coreruleset-$crs_ver/crs-setup.conf.example /usr/local/coreruleset-$crs_ver/crs-setup.conf

# Step 7 - Enable modsecurity and add rules file to default site
sed -i 's/server_name _;/server_name _;\n\tmodsecurity on;\n\tmodsecurity_rules_file \/etc\/nginx\/modsec\/main.conf;/' /etc/nginx/sites-enabled/default
touch /etc/nginx/modsec/main.conf
echo "Include /etc/nginx/modsec/modsecurity.conf" >> /etc/nginx/modsec/main.conf
echo "Include /usr/local/coreruleset-$crs_ver/crs-setup.conf" >> /etc/nginx/modsec/main.conf
echo "Include /usr/local/coreruleset-$crs_ver/rules/*.conf" >> /etc/nginx/modsec/main.conf

# Step 8 - Restart Nginx
nginx -s reload
sleep 5 # Allow config to be reloaded before testing

# Test 2 - After enabling ModSec blocking & adding rules
logger "Test 2 should return a 403 status code:"
test2=$(curl -s -H "User-Agent: nessustest" http://localhost/)
if echo "$test2" | grep -q "403"; then 
        logger "403 found - Blocking successful. PASS"
else
        logger "No 403 found - Blocking unsuccessful. FAIL"
fi

# Clean up

# V1.1 - remove swapfile if previously created
if [ "$swapen" -eq "1" ]; then
    swapoff -v /swapfile
	rm /swapfile
fi

## Revert NeedRestart config
sed -i 's/$nrconf{restart} = '\''a'\'';/#$nrconf{restart} = '\''i'\'';/' /etc/needrestart/needrestart.conf

logger "End script"

echo "## See $logname for details/test results."