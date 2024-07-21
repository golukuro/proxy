#!/bin/bash

# Function to uninstall Squid Proxy Server
uninstall_squid() {
    echo "Uninstalling Squid Proxy Server..."
    sudo apt remove --purge -y squid
    sudo rm -rf /etc/squid
    sudo rm -rf /var/log/squid
    sudo rm -rf /var/spool/squid
    echo "Squid Proxy Server has been uninstalled."
}

# Function to install Squid Proxy Server
install_squid() {
    echo "Installing Squid Proxy Server..."
    sudo apt update
    sudo apt install -y squid apache2-utils

    # Backup original Squid configuration file
    sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.bak

    # Create new Squid configuration file with basic settings
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

# Customized access controls based on username
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

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

    # Create Squid password file with username and password
    sudo htpasswd -b -c /etc/squid/passwd pradip pradip123

    # Adjust permissions for Squid password file
    sudo chmod 600 /etc/squid/passwd

    # Restart Squid service to apply changes
    sudo systemctl restart squid

    echo "Squid Proxy Server has been installed and configured."
    echo "Username: pradip"
    echo "Password: pradip123"
}

# Main script logic
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

echo "Welcome to Squid Proxy Server Setup Script!"

while true; do
    echo "Select an option:"
    echo "1. Install Squid Proxy Server"
    echo "2. Uninstall Squid Proxy Server"
    echo "3. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            install_squid
            ;;
        2)
            uninstall_squid
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select a valid option."
            ;;
    esac
done
