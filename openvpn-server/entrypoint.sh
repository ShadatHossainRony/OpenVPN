#!/bin/bash
set -e

# Wait for CA server to be ready
echo "Waiting for CA server to be ready..."
while [ ! -f /shared/ca/ca.crt ]; do
    sleep 5
done

# Generate server keys and certificates if they don't exist
if [ ! -f /shared/keys/server.key ]; then
    echo "Generating server keys and certificate request..."
    
    # Copy EasyRSA files
    mkdir -p /etc/openvpn/easy-rsa
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
    cd /etc/openvpn/easy-rsa
    
    # Initialize the PKI
    ./easyrsa init-pki
    
    # Generate server key and request
    ./easyrsa --batch gen-req server nopass
    
    # Copy the key and request to shared volume
    mkdir -p /shared/keys
    cp /etc/openvpn/easy-rsa/pki/private/server.key /shared/keys/
    cp /etc/openvpn/easy-rsa/pki/reqs/server.req /shared/requests/
    
    echo "Server key and certificate request generated."
fi

# Wait for the server certificate to be signed
echo "Waiting for server certificate to be signed..."
while [ ! -f /shared/certs/server.crt ]; do
    sleep 5
done

# Create OpenVPN server configuration
cat > /etc/openvpn/server.conf << EOF
port 1194
proto udp
dev tun

ca /shared/ca/ca.crt
cert /shared/certs/server.crt
key /shared/keys/server.key
dh /shared/ca/dh.pem
tls-auth /shared/ca/ta.key 0

server ${SERVER_NETWORK} ${SERVER_NETMASK}
ifconfig-pool-persist /etc/openvpn/ipp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Push routes to the LAN
push "route ${PUSH_ROUTES}"

keepalive 10 120
cipher AES-256-CBC
user nobody
group nobody
persist-key
persist-tun
status /etc/openvpn/openvpn-status.log
verb 3
EOF

# Create client certificate generation script
cat > /etc/openvpn/generate_client.sh << 'EOF'
#!/bin/bash
set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

CLIENT=$1

# Generate client key and request
cd /etc/openvpn/easy-rsa
./easyrsa --batch gen-req $CLIENT nopass

# Copy the key and request to shared volume
cp /etc/openvpn/easy-rsa/pki/private/$CLIENT.key /shared/keys/
cp /etc/openvpn/easy-rsa/pki/reqs/$CLIENT.req /shared/requests/

echo "Client key and certificate request generated for $CLIENT."
echo "Waiting for certificate to be signed..."

# Wait for the client certificate to be signed
while [ ! -f /shared/certs/$CLIENT.crt ]; do
    sleep 2
done

echo "Certificate signed. Generating client configuration..."

# Create client configuration
cat > /etc/openvpn/clients/$CLIENT.ovpn << CLIENTCONF
client
dev tun
proto udp
remote 192.168.1.102 1194 # change the server address to the desired address
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat /shared/ca/ca.crt)
</ca>
<cert>
$(cat /shared/certs/$CLIENT.crt)
</cert>
<key>
$(cat /shared/keys/$CLIENT.key)
</key>
<tls-auth>
$(cat /shared/ca/ta.key)
</tls-auth>
key-direction 1
CLIENTCONF

echo "Client configuration generated: /etc/openvpn/clients/$CLIENT.ovpn"
EOF

chmod +x /etc/openvpn/generate_client.sh

# Create clients directory
mkdir -p /etc/openvpn/clients

# Set up IP forwarding and iptables rules
echo "Setting up IP forwarding and iptables rules..."
# echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s ${SERVER_NETWORK}/${SERVER_NETMASK} -o eth0 -j MASQUERADE

# Start OpenVPN server
echo "Starting OpenVPN server..."
openvpn --config /etc/openvpn/server.conf
