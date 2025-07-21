#!/bin/bash

KSTDLIB_DATE=2025-07-20

ARCH=$(dpkg --print-architecture)
if [ "$ARCH" == "amd64" ]; then
   ARCH="x86_64"
elif [ "$ARCH" == "arm64" ]; then
   ARCH="aarch64"
else
   echo "Architecture ${ARCH} is not supported"
   exit 1
fi

KSTDLIB_VERSION=$(echo $KSTDLIB_DATE|sed 's/-//g')
KSTDLIB_TGZ=swift-${ARCH}-${KSTDLIB_DATE}-a-linux.tar.gz
KSTDLIB_URL=https://github.com/spevans/swift-kstdlib/releases/download/v${KSTDLIB_VERSION}/${KSTDLIB_TGZ}

cd /
echo Downloading ${KSTDLIB_URL}
curl -fSL ${KSTDLIB_URL} -o /tmp/${KSTDLIB_TGZ}
tar zxvf /tmp/${KSTDLIB_TGZ} --directory=/
