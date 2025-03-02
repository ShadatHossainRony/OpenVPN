#!/bin/bash
# Script to generate a client configuration from the host

if [ $# -ne 1 ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

CLIENT=$1

# Execute the client generation script inside the container
sudo docker exec -it openvpn-server /etc/openvpn/generate_client.sh $CLIENT

# Copy the client configuration from the container to the host
sudo docker cp openvpn-server:/etc/openvpn/clients/$CLIENT.ovpn ./clients/$CLIENT.ovpn

echo "Client configuration has been generated and copied to ./clients/$CLIENT.ovpn"
