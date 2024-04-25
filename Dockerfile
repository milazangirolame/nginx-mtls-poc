FROM nginx:latest

RUN echo "127.0.0.1 example.test" >> /etc/hosts_custom

RUN echo "resolver 127.0.0.11 valid=1s;" > /etc/nginx/conf.d/resolver.conf


COPY ./nginx/conf.d/nginx.conf /etc/nginx/conf.d/nginx.conf
COPY ./nginx/certs/ca_root.crt /etc/nginx/conf.d/certs/ca_root.crt
COPY ./nginx/certs/ca_root.key /etc/nginx/conf.d/certs/ca_root.key
COPY ./nginx/certs/server.crt /etc/nginx/conf.d/certs/server.crt
COPY ./nginx/certs/server.key /etc/nginx/conf.d/certs/server.key
COPY ./nginx/certs/client.crt /etc/nginx/conf.d/certs/client.crt
COPY ./nginx/certs/client.key /etc/nginx/conf.d/certs/client.key

# !!!
RUN chmod 644 /etc/nginx/conf.d/certs/server.crt \
    && chmod 644 /etc/nginx/conf.d/certs/server.key

RUN chmod 644 /etc/nginx/conf.d/certs/client.crt \
    && chmod 600 /etc/nginx/conf.d/certs/client.key

EXPOSE 443

CMD ["bash", "-c", "nginx -g 'daemon off;'"]

