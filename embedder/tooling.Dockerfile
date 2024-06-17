FROM debian:latest
LABEL org.opencontainers.image.description="Container to run flutter pi tools in. Useful on immutable operating systems."

RUN apt-get update
RUN apt-get install --no-install-recommends -y wget ca-certificates xz-utils git cmake

WORKDIR /opt
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz -O flutter.tar.xz
RUN tar xf flutter.tar.xz
RUN rm flutter.tar.xz

RUN chmod -R o+w /opt/flutter
ENV PATH="/opt/flutter/bin/:$PATH"

RUN dart --disable-analytics
RUN flutter config --no-analytics
RUN flutter precache
