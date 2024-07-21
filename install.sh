#!/bin/bash

# Update package lists and install Squid
echo "Installing Squid Proxy Server..."
sudo apt update
sudo apt install -y squid

# Backup original Squid configuration file
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Create a new Squid configuration file with customized settings
sudo tee /etc/squid/squid.conf > /dev/null << 'EOF'
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

# Set up username and password for Squid proxy
sudo sh -c "printf 'pradip:$(openssl passwd -apr1 123456)\n' >> /etc/squid/passwd"

# Adjust permissions on Squid password file
sudo chmod 600 /etc/squid/passwd

# Restart Squid service to apply changes
sudo systemctl restart squid.service

echo "Squid Proxy installation and configuration completed successfully."
