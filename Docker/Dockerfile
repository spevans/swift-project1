# Run using: docker build --tag=swift-kstdlib  .
FROM swift:5.0.2-bionic

ARG KSTDLIB_VERSION=20190906
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


# Copy any locals kstdlib tgzs to /tmp
COPY * /tmp/

WORKDIR /

RUN echo Downloading ${KSTDLIB_URL} \
    && curl -fSL ${KSTDLIB_URL} -o /tmp/kstdlib-${KSTDLIB_VERSION}.tgz \
    && apt-get purge -y curl \
    && apt-get -y autoremove


# Install any kstdlib.tgzs in /tmp

RUN for tgz in `ls /tmp/*.tgz`;          \
    do echo tgz: $tgz ;                  \
       if [ -f $tgz ];                   \
           then echo Installing $tgz ;   \
           tar zxf $tgz --directory ~ ; \
           rm -f $tgz                  ; \
       fi;                               \
    done


RUN ~/swift/usr/bin/swift --version \
    && ~/swift/usr/bin/clang --version \
    && ~/kstdlib-${KSTDLIB_VERSION}/usr/bin/swift --version \
    && ~/kstdlib-${KSTDLIB_VERSION}/usr/bin/clang --version
