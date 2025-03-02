# OpenVPN Server with EasyRSA CA
VPNs provide a secure mean to communicate with services by encrypting the information and sending through a tunnel. As much important they are, VPNs are tedious to configure. Containerize them is another hassle. 
This project sets up a secure VPN service using OpenVPN and EasyRSA in a Docker Compose environment Though it is done and tested on the LAN, it works on any remote servers also. It consists of two separate containers:

1. **CA Server**: Manages the Certificate Authority for signing certificate requests
2. **OpenVPN Server**: Provides the VPN service to LAN users(It can be changed to any server)

## Architecture

- **CA Server**: Responsible for managing the PKI (Public Key Infrastructure) and signing certificate requests
- **OpenVPN Server**: Handles VPN connections from clients
- **Shared Volume**: Facilitates secure exchange of certificate requests, signed certificates, and keys between containers

## Setup Instructions

1. Clone this repository
2. Configure environment variables in the docker-compose.yml file if needed
3. Start the services:

```bash
docker-compose up -d
```

4. Generate client certificates:

```bash
docker exec -it openvpn-server /etc/openvpn/generate_client.sh client1
```
or 
```run the script
./generate_client.sh client_name
```

5. The client configuration file will be available at:

```
/etc/openvpn/clients/client1.ovpn
```

## Security Features

- Separate CA and VPN servers for enhanced security
- TLS authentication for additional protection
- Strong encryption with AES-256-CBC
- Secure key exchange using 2048-bit keys

## Network Configuration

- VPN Network: 10.8.0.0/24 (configurable via environment variables)
- Clients will have access to the LAN (192.168.1.0/24)
- DNS servers: 8.8.8.8 and 8.8.4.4 (Google DNS)

## Client Management

To add a new client:

```bash
docker exec -it openvpn-server /etc/openvpn/generate_client.sh <client_name>
```
or 
```run the script
./generate_client.sh client_name
```

To revoke a client certificate:

```bash
docker exec -it ca-server /etc/openvpn/easy-rsa/easyrsa revoke <client_name>
docker exec -it ca-server /etc/openvpn/easy-rsa/easyrsa gen-crl
```

## Customization

You can customize the following environment variables in the docker-compose.yml file:

- `SERVER_NETWORK`: VPN subnet (default: 10.8.0.0)
- `SERVER_NETMASK`: VPN subnet mask (default: 255.255.255.0)
- `PUSH_ROUTES`: Routes to push to clients (default: 192.168.0.0 255.255.0.0)
- Various EasyRSA parameters for certificate generation
