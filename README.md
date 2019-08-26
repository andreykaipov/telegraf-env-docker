# telegraf-env-docker

[![Docker Repository on Quay](https://quay.io/repository/qoqodev/telegraf/status "Docker Repository on Quay")](https://quay.io/repository/qoqodev/telegraf)
[![CircleCI](https://img.shields.io/circleci/build/github/andreykaipov/telegraf-env-docker/master.svg)](https://circleci.com/gh/andreykaipov/telegraf-env-docker)

## what is this?

This is a wrapper around the [official Telegraf Docker image](https://hub.docker.com/_/telegraf/)
from [InfluxData](https://www.influxdata.com/) with a custom entrypoint to handle configuration
through environment variables rather than through a traditional file mount.

## example

Traditionally, one would either bake the Telegraf configuration into an image, or maintain it
outside of the image, mounting the file to the appropriate location before starting the container.
For example, the following creates a Telegraf config file that prints `hey value=1` every second to stdout.

```shell

└▶ tee /tmp/telegraf.conf <<EOF
[agent]
    quiet = true
    omit_hostname = true
    interval = "1s"
    flush_interval = "1s"
[[inputs.exec]]
    commands = ["echo hey value=1"]
    data_format = "influx"
[[outputs.file]]
    files = ["stdout"]
EOF

└▶ docker run --rm -v /tmp/telegraf.conf:/etc/telegraf/telegraf.conf telegraf:alpine
2019-08-26T04:41:58Z I! Starting Telegraf 1.11.3
2019-08-26T04:41:58Z I! Using config file: /etc/telegraf/telegraf.conf
hey value=1 1566794519000000000
hey value=1 1566794520000000000
hey value=1 1566794521000000000
```

On the other hand, the equivalent configuration through environment variables using the image in this repo is as follows:

```bash
└▶ docker run --rm -e agent.quiet=true \
                   -e agent.omit_hostname=true \
                   -e agent.interval=1s \
                   -e agent.flush_interval=1s \
                   -e inputs.exec[0].commands[0]="echo hey value=1" \
                   -e inputs.exec[0].data_format=influx \
                   -e outputs.file[0].files[0]=stdout quay.io/qoqodev/telegraf:alpine
2019-08-26T04:42:13Z I! Starting Telegraf 1.11.3
2019-08-26T04:42:13Z I! Using config file: /etc/telegraf/telegraf.conf
hey value=1 1566794534000000000
hey value=1 1566794535000000000
hey value=1 1566794536000000000
```

No file mount necessary!

## how does it work?

The entrypoint of this image uses [env2conf](https://github.com/andreykaipov/env2conf) to convert
specific environment variables into TOML, writing the content to Telegraf's default configuration
file `/etc/telegraf/telegraf.conf`.

## questions

#### what tags are available?
  
The same ones for the official Telegraf image. The pipeline for this repo has a nightly sync job to check if
any upstream Telegraf images have been updated, and will rebuild this image appropriately.
  
#### can i still use the traditional mount approach with this image?

Sure, but because the entrypoint will always override `/etc/telegraf/telegraf.conf`, you'll have to
mount your file somewhere else, and tell Telegraf where to find it with the `--config` flag. For example,
```
└▶ docker run --rm -v /tmp/telegraf.conf:/opt/telegraf.conf quay.io/qoqodev/telegraf:alpine --config /opt/telegraf.conf
```

#### translating between environment variables and TOML feels odd

You're right - it is odd. It may help to first imagine your Telegraf TOML configuration file as JSON,
and then convert that into an environmental variable representation of that.
