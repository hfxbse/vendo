FROM debian:bookworm AS embedder-builder

RUN dpkg --add-architecture arm64
RUN apt-get update
RUN apt-get install --no-install-recommends -y  \
    cmake  \
    make  \
    git  \
    ca-certificates \
    pkg-config \
    crossbuild-essential-arm64  \
    \
    libvulkan-dev:arm64 \
    libgl1-mesa-dev:arm64  \
    libgles2-mesa-dev:arm64  \
    libegl1-mesa-dev:arm64  \
    libdrm-dev:arm64  \
    libgbm-dev:arm64  \
    libsystemd-dev:arm64  \
    libinput-dev:arm64  \
    libudev-dev:arm64  \
    libxkbcommon-dev:arm64 \
    libgstreamer1.0-dev:arm64  \
    libgstreamer-plugins-base1.0-dev:arm64  \
    libgstreamer-plugins-bad1.0-dev:arm64  \
    gstreamer1.0-plugins-base:arm64  \
    gstreamer1.0-plugins-good:arm64  \
    gstreamer1.0-plugins-ugly:arm64  \
    gstreamer1.0-plugins-bad:arm64  \
    gstreamer1.0-libav:arm64  \
    gstreamer1.0-alsa:arm64

ENV CC="aarch64-linux-gnu-gcc"
ENV CXX="aarch64-linux-gnu-gpp"
ENV PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
ENV PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu"
ENV PKG_CONFIG_SYSROOT_DIR="/"

RUN echo " \
    git clone https://github.com/ardera/flutter-pi.git && \
    mkdir flutter-pi/build &&  \
    cd flutter-pi/build &&  \
    cmake -DENABLE_VULKAN=On -DVULKAN_DEBUG=OFF .. && \
    make -j `nproc` \
    " >> /build.sh

ENTRYPOINT ["/bin/bash", "/build.sh"]
