FROM alpine:3.18

RUN apk add --no-cache openvpn easy-rsa bash iptables

WORKDIR /etc/openvpn

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1194/udp

CMD ["tail", "-f", "/dev/null"]