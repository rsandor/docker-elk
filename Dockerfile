FROM qnib/logstash
MAINTAINER "Christian Kniep <christian@qnib.org>"

ADD ./docker-elk/etc/yum.repos.d/elasticsearch-1.4.repo /etc/yum.repos.d/
RUN yum install -y which zeromq && \
    ln -s /usr/lib64/libzmq.so.1 /usr/lib64/libzmq.so

# elasticsearch
RUN yum install -y elasticsearch && \
    sed -i '/# cluster.name:.*/a cluster.name: logstash' /etc/elasticsearch/elasticsearch.yml
ADD ./docker-elk/etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/
ADD ./docker-elk/etc/supervisord.d/elasticsearch.ini /etc/supervisord.d/elasticsearch.ini

# diamond collector
ADD ./docker-elk/etc/diamond/collectors/ElasticSearchCollector.conf /etc/diamond/collectors/ElasticSearchCollector.conf

# nginx
RUN yum install -y nginx httpd-tools
ADD ./docker-elk/etc/nginx/ /etc/nginx/
ADD ./docker-elk/etc/diamond/collectors/NginxCollector.conf /etc/diamond/collectors/NginxCollector.conf

# Add QNIBInc repo
RUN echo "20140917.1"; yum clean all; yum install -y qnib-statsd qnib-grok-patterns

## Kibana3
ENV KIBANA_VER 3.1.2
WORKDIR /var/www/
RUN curl -s -o /tmp/kibana-${KIBANA_VER}.tar.gz https://download.elasticsearch.org/kibana/kibana/kibana-${KIBANA_VER}.tar.gz && \
    tar xf /tmp/kibana-${KIBANA_VER}.tar.gz && rm -f /tmp/kibana-${KIBANA_VER}.tar.gz && \
    mv kibana-${KIBANA_VER} kibana
ADD ./docker-elk/etc/nginx/conf.d/kibana.conf /etc/nginx/conf.d/kibana.conf
WORKDIR /etc/nginx/
# Config kibana-Dashboards
ADD ./docker-elk/var/www/kibana/app/dashboards/ /var/www/kibana/app/dashboards/
ADD ./docker-elk/var/www/kibana/config.js /var/www/kibana/config.js

## Kibana4
WORKDIR /opt/
ENV KIBANA_VER 4.0.2
RUN curl -s -L -o kibana-${KIBANA_VER}-linux-x64.tar.gz https://download.elasticsearch.org/kibana/kibana/kibana-${KIBANA_VER}-linux-x64.tar.gz && \
    tar xf kibana-${KIBANA_VER}-linux-x64.tar.gz && \
    rm /opt/kibana*.tar.gz
RUN ln -sf /opt/kibana-${KIBANA_VER}-linux-x64 /opt/kibana
ADD ./docker-elk/etc/supervisord.d/kibana.ini /etc/supervisord.d/
ADD ./docker-elk/etc/consul.d/check_kibana4.json /etc/consul.d/
# Config kibana4
ADD ./docker-elk/opt/kibana/config/kibana.yml /opt/kibana/config/kibana.yml

# logstash config
ADD ./docker-elk/etc/default/logstash/ /etc/default/logstash/

ADD ./docker-elk/etc/consul.d/ /etc/consul.d/
ADD ./docker-elk/opt/qnib/bin/ /opt/qnib/bin/
ADD ./docker-elk/etc/diamond/handlers/InfluxdbHandler.conf /etc/diamond/handlers/InfluxdbHandler.conf
ADD ./docker-elk/etc/supervisord.d/ /etc/supervisord.d/

# Test key and cert
ADD ./docker-elk/etc/pki/tls/certs/logstash-forwarder.crt /etc/pki/tls/certs/logstash-forwarder.crt
ADD ./docker-elk/etc/pki/tls/private/logstash-forwarder.key /etc/pki/tls/private/logstash-forwarder.key
