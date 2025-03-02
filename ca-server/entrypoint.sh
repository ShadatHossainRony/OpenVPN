#!/bin/bash
set -e

# Initialize the PKI if it doesn't exist
if [ ! -d "/etc/openvpn/easy-rsa/pki" ]; then
    echo "Initializing PKI..."
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
    
    # Initialize the PKI
    ./easyrsa init-pki
    
    # Build CA
    echo "Building CA..."
    ./easyrsa --batch --req-cn="VPN CA" build-ca nopass
    
    # Generate Diffie-Hellman parameters
    echo "Generating DH parameters..."
    ./easyrsa gen-dh
    
    # Generate TLS key for additional security
    echo "Generating TLS key..."
    openvpn --genkey --secret /etc/openvpn/easy-rsa/pki/ta.key
    
    # Copy necessary files to shared volume
    echo "Copying CA files to shared volume..."
    mkdir -p /shared/ca
    cp /etc/openvpn/easy-rsa/pki/ca.crt /shared/ca/
    cp /etc/openvpn/easy-rsa/pki/dh.pem /shared/ca/
    cp /etc/openvpn/easy-rsa/pki/ta.key /shared/ca/
fi

# Create a function to sign certificate requests
sign_certificate() {
    local req_file=$1
    local cert_name=$(basename "$req_file" .req)
    
    if [ -f "$req_file" ]; then
        echo "Signing certificate request: $cert_name"
        
        # Import the request
        ./easyrsa import-req "$req_file" "$cert_name"
        
        # Sign the request
        if [[ "$cert_name" == "server" ]]; then
            ./easyrsa --batch sign-req server "$cert_name"
        else
            ./easyrsa --batch sign-req client "$cert_name"
        fi
        
        # Copy the signed certificate to the shared volume
        cp "/etc/openvpn/easy-rsa/pki/issued/${cert_name}.crt" "/shared/certs/"
        
        # Remove the request file
        rm "$req_file"
        
        echo "Certificate signed: $cert_name"
    fi
}

# Create directories in shared volume
mkdir -p /shared/requests
mkdir -p /shared/certs
mkdir -p /shared/keys

# Monitor the requests directory for new certificate requests
echo "Starting certificate signing service..."
while true; do
    for req_file in /shared/requests/*.req; do
        if [ -f "$req_file" ]; then
            sign_certificate "$req_file"
        fi
    done
    sleep 5
done