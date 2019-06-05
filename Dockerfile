FROM telegraf:1.10-alpine
COPY . /opt
ENTRYPOINT ["/opt/entrypoint.sh"]
