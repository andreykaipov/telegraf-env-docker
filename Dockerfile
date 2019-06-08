ARG base=latest
FROM telegraf:$base
COPY *.sh /opt/
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["telegraf"]
