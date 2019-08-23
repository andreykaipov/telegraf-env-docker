ARG base=latest
FROM telegraf:$base
RUN wget -O env2conf https://github.com/andreykaipov/env2conf/releases/download/v0.2.0/env2conf-0.2.0-linux-amd64 && \
    chmod +x env2conf && \
    mv env2conf /usr/local/bin
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
