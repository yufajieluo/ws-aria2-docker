FROM alpine

MAINTAINER wangshuai <itwangshuai@126.com>

RUN apk update && \
    apk add aria2 && \
    apk add nginx && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /opt/aria2/conf && \
    mkdir -p /opt/aria2/ariang && \
    touch /opt/aria2/conf/aria2.session

ADD aria2.conf /opt/aria2/conf/aria2.conf
ADD nginx.conf /etc/nginx/nginx.conf

RUN wget https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip -P /opt/aria2/ariang && \
    cd /opt/aria2/ariang && \
    unzip master.zip && \
    rm -f master.zip && \
    rm -f /etc/nginx/conf.d/*.conf

RUN echo "#!/bin/sh" > /opt/aria2/startup.sh && \
    echo "sed -i s/PORT_RPC/\${ENV_PORT_RPC}/g /opt/aria2/conf/aria2.conf" >> /opt/aria2/startup.sh && \
    echo "sed -i s/PORT_BT/\${ENV_PORT_BT}/g /opt/aria2/conf/aria2.conf" >> /opt/aria2/startup.sh && \
    echo "sed -i s/PORT_DHT/\${ENV_PORT_DHT}/g /opt/aria2/conf/aria2.conf" >> /opt/aria2/startup.sh && \
    echo "sed -i s/RPC_SECRET/\${ENV_RPC_SECRET}/g /opt/aria2/conf/aria2.conf" >> /opt/aria2/startup.sh && \
    echo "sed -i s/PORT_WEB/\${ENV_PORT_WEB}/g /etc/nginx/nginx.conf" >> /opt/aria2/startup.sh && \
    echo "nohup aria2c --conf-path=/opt/aria2/conf/aria2.conf -D >/dev/null 2>&1 &" >> /opt/aria2/startup.sh && \
    echo "nginx" >> /opt/aria2/startup.sh && \
    echo "tail -f /dev/null" >> /opt/aria2/startup.sh && \
    chmod +x /opt/aria2/startup.sh

ENV ENV_PORT_RPC OCC_PORT_RPC
ENV ENV_PORT_BT OCC_PORT_BT
ENV ENV_PORT_DHT OCC_PORT_DHT
ENV ENV_PORT_WEB OCC_PORT_WEB
ENV ENV_RPC_SECRET OCC_RPC_SECRET

EXPOSE OCC_PORT_RPC
EXPOSE OCC_PORT_BT
EXPOSE OCC_PORT_DHT
EXPOSE OCC_PORT_WEB

CMD ["/opt/aria2/startup.sh"]
