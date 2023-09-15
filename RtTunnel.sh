#!/bin/bash

# Author: Lord Of The Shadows

version="1.0"

# Function to check if wget is installed, and install it if not
check_dependencies() {
    if ! command -v wget &> /dev/null; then
        echo "wget is not installed. Installing..."
        sudo apt-get install wget
    fi
}

# Check installed service
check_installed() {
    if [ -f "/etc/systemd/system/tunnel.service" ]; then
        echo "The service is already installed."
        exit 1
    fi
}

# Function to download and install RTT
install_rtt() {
    wget "https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/install.sh" -O install.sh && chmod +x install.sh && bash install.sh
}

# Function to configure arguments based on user's choice
configure_arguments() {
    read -p "Which server do you want to use? (Enter '1' for Iran or '2' for Kharej): " server_choice
    read -p "Please Enter SNI (default: splus.ir): " sni
    sni=${sni:-splus.ir}

    if [ "$server_choice" == "2" ]; then
        read -p "Choose server type for Kharej (Enter '1' for IP or '2' for DNS): " kharej_server_type
        if [ "$kharej_server_type" == "1" ]; then
            read -p "Please Enter IP for Kharej server: " kharej_ip
            kharej_argument="--kharej --kharej-ip:$kharej_ip"
        elif [ "$kharej_server_type" == "2" ]; then
            read -p "Please Enter DNS for Kharej server: " kharej_dns_name
            kharej_argument="--kharej --kharej-dns:$kharej_dns_name"
        else
            echo "Invalid choice. Please enter '1' or '2'."
            exit 1
        fi

        read -p "Please Enter Password (Please choose the same password on both servers): " password
        arguments="$kharej_argument --iran-port:443 --toip:127.0.0.1 --toport:multiport --password:$password --sni:$sni --terminate:24"
    elif [ "$server_choice" == "1" ]; then
        read -p "Choose server type for Iran (Enter '1' for IP or '2' for DNS): " iran_server_type
        if [ "$iran_server_type" == "1" ]; then
            read -p "Please Enter IP for Iran server: " iran_ip
            iran_argument="--iran --iran-ip:$iran_ip"
        elif [ "$iran_server_type" == "2" ]; then
            read -p "Please Enter DNS for Iran server: " iran_dns_name
            iran_argument="--iran --iran-dns:$iran_dns_name"
        else
            echo "Invalid choice. Please enter '1' or '2'."
            exit 1
        fi

        read -p "Please Enter Password (Please choose the same password on both servers): " password
        arguments="$iran_argument --lport:23-65535 --sni:$sni --password:$password --terminate:24"
    else
        echo "Invalid choice. Please enter '1' or '2'."
        exit 1
    fi
}

# Function to handle installation
install() {
    check_dependencies
    check_installed
    install_rtt
    # Change directory to /etc/systemd/system
    cd /etc/systemd/system

    configure_arguments

    # Create a new service file named tunnel.service
    cat <<EOL > tunnel.service
[Unit]
Description=my tunnel service

[Service]
User=root
WorkingDirectory=/root
ExecStart=/root/RTT $arguments
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemctl daemon and start the service
    sudo systemctl daemon-reload
    sudo systemctl start tunnel.service
    sudo systemctl enable tunnel.service
}

# Function to handle uninstallation
uninstall() {
    # Check if the service is installed
    if [ ! -f "/etc/systemd/system/tunnel.service" ]; then
        echo "The service is not installed."
        return
    fi

    # Stop and disable the service
    sudo systemctl stop tunnel.service
    sudo systemctl disable tunnel.service

    # Remove service file
    sudo rm /etc/systemd/system/tunnel.service
    sudo systemctl reset-failed
    sudo rm RTT
    sudo rm install.sh

    echo "Uninstallation completed successfully."
}

check_update() {
    # Get the current installed version of RTT
    installed_version=$(./RTT -v 2>&1 | grep -o '"[0-9.]*"')

    # Fetch the latest version from GitHub releases
    latest_version=$(curl -s https://api.github.com/repos/radkesvat/ReverseTlsTunnel/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d":" -f2 | sed 's/["V ]//g' | sed 's/^/"/;s/$/"/')

    # Compare the installed version with the latest version
    if [[ "$latest_version" > "$installed_version" ]]; then
        echo "A new version is available, please reinstall: $latest_version (Installed: $installed_version)."
    else
        echo "You have the latest version ($installed_version)."
    fi
}

#ip & version
myip=$(hostname -I | awk '{print $1}')

# Main menu
clear
echo "Author: Lord Of The Shadows"
echo "Your IP is: ($myip) "
echo ""
echo " --------#- Reverse Tls Tunnel -#--------"
echo "1) Install (Multiport)"
echo "2) Uninstall"
echo "3) Check Update"
echo "0) Exit"
echo " --------------Version $version---------------"
read -p "Please choose: " choice

case $choice in
    1)
        install
        ;;
    2)
        uninstall
        ;;
    3)
        check_update
        ;;
    0)
        exit
        ;;
    *)
        echo "Invalid choice. Please try again."
        ;;
esac
