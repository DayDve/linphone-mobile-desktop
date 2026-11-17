# Build environment for linphone-sdk + linphone-desktop on Debian forky (Mobian), arm64.
# Third-party libraries come from Debian instead of the sdk's external/* submodules.
FROM debian:forky-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      cmake ninja-build g++ make pkg-config git ca-certificates file patchelf dpkg-dev \
      nasm yasm perl intltool python3 python3-pystache python3-six doxygen graphviz \
      qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-tools-dev qt6-tools-dev-tools \
      qt6-l10n-tools qt6-svg-dev qt6-5compat-dev qt6-networkauth-dev \
      qt6-wayland-dev qt6-wayland-private-dev libwayland-dev \
      libssl-dev libmbedtls-dev libsrtp2-dev libdecaf-dev libsoci-dev libsqlite3-dev \
      libxerces-c-dev libxml2-dev zlib1g-dev libjsoncpp-dev libldap-dev \
      libopus-dev libspeex-dev libspeexdsp-dev libgsm1-dev libbcg729-dev libcodec2-dev \
      libopencore-amrnb-dev libopencore-amrwb-dev libvo-amrwbenc-dev librnnoise-dev \
      libvpx-dev libopenh264-dev libyuv-dev libturbojpeg0-dev libzxing-dev libhidapi-dev \
      libv4l-dev libpulse-dev libasound2-dev libgl-dev libglew-dev libx11-dev libxv-dev \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=C.UTF-8
