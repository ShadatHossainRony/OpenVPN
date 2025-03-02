#!/bin/bash
# Script to revoke a client certificate

if [ $# -ne 1 ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

CLIENT=$1

# Revoke the client certificate
sudo docker exec -it ca-server /etc/openvpn/easy-rsa/easyrsa revoke $CLIENT

# Generate a new CRL (Certificate Revocation List)
sudo docker exec -it ca-server /etc/openvpn/easy-rsa/easyrsa gen-crl

# Copy the CRL to the OpenVPN server
sudo docker exec -it ca-server cp /etc/openvpn/easy-rsa/pki/crl.pem /shared/ca/

echo "Client certificate for $CLIENT has been revoked"
