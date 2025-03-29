FROM debian:bookworm-20250317-slim

LABEL org.opencontainers.image.source=https://github.com/hfxbse/vendo
LABEL org.opencontainers.image.description="Enviroment to package the release as deb."

RUN apt-get update
RUN apt-get install -y --no-install-recommends unzip zip
