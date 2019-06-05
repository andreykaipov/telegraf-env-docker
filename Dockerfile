FROM telegraf:1.10-alpine
COPY *.sh /opt/
ENTRYPOINT ["/opt/entrypoint.sh"]
