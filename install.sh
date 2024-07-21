#!/bin/bash

# Install Squid Proxy Server
echo "Installing Squid Proxy Server..."
apt update
apt install -y squid

# Backup default Squid configuration
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Create a new Squid configuration
cat <<EOF > /etc/squid/squid.conf
# Recommended minimum configuration:
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# Example rule to allow access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 192.168.0.0/24   # RFC1918 possible internal network
acl localnet src 10.0.0.0/8       # RFC1918 possible internal network
acl localnet src 172.16.0.0/12    # RFC1918 possible internal network

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# Allow access from localhost and localnet
http_access allow localhost
http_access allow localnet

# Customized access controls based on username
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

# Deny all other access to this proxy
http_access deny all

# Squid port configuration
http_port 3128

# Uncomment and adjust the following to add a disk cache directory
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

# Customized error pages
error_directory /usr/share/squid/errors/English

# Add your own customized error pages
deny_info ERR_ACCESS_DENIED all

# Start Squid Proxy Service
service squid restart

EOF

# Set up basic authentication with username and password
htpasswd -b -c /etc/squid/passwd pradip 123456

# Restart Squid to apply changes
service squid restart

echo "Squid proxy installation and configuration completed successfully."
