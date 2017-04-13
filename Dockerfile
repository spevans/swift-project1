FROM ubuntu:16.04
MAINTAINER Abhishek Munie <dev@abhishekmunie.com>

RUN apt-get -q update && \
    apt-get -q install -y \
    make \
    clang \
    libicu-dev \
    libxml2 \
    libcurl4-openssl-dev \
    nasm \
    git

WORKDIR /root/swift-project1

CMD make
