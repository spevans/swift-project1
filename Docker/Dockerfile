# Run using: docker build --tag=swift-kstdlib  .
FROM ubuntu:24.04

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    binutils              \
    binutils-x86-64-linux-gnu \
    libgcc-12-dev         \
    libncurses-dev        \
    libsqlite3-dev        \
    libxml2-dev           \
    file                  \
    nasm                  \
    xorriso               \
    mtools                \
    dosfstools            \
    make                  \
    curl                  \
    less                  \
    git                   \
    && rm -r /var/lib/apt/lists/*


# Copy any locals kstdlib tgzs to /tmp
COPY * /tmp/

WORKDIR /
RUN /tmp/install-toolchain.sh