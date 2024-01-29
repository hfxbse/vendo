FROM debian:latest
LABEL org.opencontainers.image.description="Container to run flutter pi in. Useful on immutable operating systems."

RUN apt-get update
RUN apt-get install --no-install-recommends -y wget ca-certificates xz-utils git cmake

WORKDIR /opt
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.8-stable.tar.xz -O flutter.tar.xz
RUN tar xf flutter.tar.xz
RUN rm flutter.tar.xz

RUN git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin/:$PATH"

RUN flutter config --no-analytics
RUN flutter precache
