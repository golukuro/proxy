#!/bin/bash

# Update package lists and install Squid
sudo apt update
sudo apt install -y squid

# Backup original Squid configuration file
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Create new Squid configuration file
cat <<EOF | sudo tee /etc/squid/squid.conf
# Recommended minimum configuration:
acl localnet src 0.0.0.1-255.255.255.255  # RFC 1122 "this" network (LAN)
acl localnet src fe80::/10               # RFC 4291 link-local (directly plugged) machines
acl SSL_ports port 443
acl Safe_ports port 80                  # http
acl Safe_ports port 21                  # ftp
acl Safe_ports port 443                 # https
acl Safe_ports port 70                  # gopher
acl Safe_ports port 210                 # wais
acl Safe_ports port 1025-65535          # unregistered ports
acl Safe_ports port 280                 # http-mgmt
acl Safe_ports port 488                 # gss-http
acl Safe_ports port 591                 # filemaker
acl Safe_ports port 777                 # multiling http
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

# Allow access from your IP range
# Example:
# acl my_ip_range src 192.168.1.0/24
# http_access allow my_ip_range

# Customized access controls based on IP
# Example:
# http_access allow my_ip1
# http_access allow my_ip2

# Allow all HTTP requests
http_access allow all

# Squid port configuration
http_port 3128

# Uncomment and adjust the following to add a disk cache directory
# cache_dir ufs /var/spool/squid 100 16 256

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
EOF

# Restart Squid service to apply changes
sudo systemctl restart squid

# Check Squid service status
sudo systemctl status squid
