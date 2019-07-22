# Run using: docker build --tag=swift-kstdlib  .
FROM swift:5.0.2-bionic

ARG KSTDLIB_VERSION=20190620
ENV KSTDLIB_VERSION=$KSTDLIB_VERSION
ENV KSTDLIB_URL=https://github.com/spevans/swift-kstdlib/releases/download/v${KSTDLIB_VERSION}/kstdlib-${KSTDLIB_VERSION}.tgz

RUN echo Building with kstdlib version ${KSTDLIB_VERSION}
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    nasm \
    xorriso \
    mtools \
    dosfstools \
    make \
    curl \
    && rm -r /var/lib/apt/lists/*


RUN echo Linking swift && ln -s / ~/swift
# Install tools required for building the project
#RUN apt-get install -y \
  

WORKDIR /
RUN echo Downloading ${KSTDLIB_URL} \
    && curl -fSL ${KSTDLIB_URL} -o /tmp/kstdlib-${KSTDLIB_VERSION}.tgz \
    && echo Installing kstdlib \
    && tar zxf /tmp/kstdlib-$KSTDLIB_VERSION.tgz --directory ~ \
    && rm /tmp/kstdlib-$KSTDLIB_VERSION.tgz \
    && apt-get purge -y curl \
    && apt-get -y autoremove


RUN ~/swift/usr/bin/swift --version \
    && ~/swift/usr/bin/clang --version \
    && ~/kstdlib-${KSTDLIB_VERSION}/usr/bin/swift --version \
    && ~/kstdlib-${KSTDLIB_VERSION}/usr/bin/clang --version
