FROM alpine:3.18

RUN apk add --no-cache openvpn easy-rsa bash

WORKDIR /etc/openvpn/easy-rsa

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["tail", "-f", "/dev/null"]