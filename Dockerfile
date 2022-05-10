# -*-Dockerfile-*-
FROM debian:stretch

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt update && \
    apt install -y build-essential curl libcurl4-openssl-dev libsqlite3-dev pkg-config git wget

RUN if [ ${TARGETPLATFORM} = 'linux/amd64' ]; then \
      wget http://downloads.dlang.org/releases/2.x/2.097.0/dmd_2.097.0-0_amd64.deb -O /tmp/dmd_amd64.deb && \
       dpkg -i /tmp/dmd_amd64.deb && \
       rm -f /tmp/dmd_amd64.deb; \
    fi && \
    if [ ${TARGETPLATFORM} = 'linux/arm64' ]; then \
      wget https://github.com/ldc-developers/ldc/releases/download/v1.17.0/ldc2-1.17.0-linux-aarch64.tar.xz && \
      tar -xvf ldc2-1.17.0-linux-aarch64.tar.xz; \
    fi

RUN wget https://github.com/abraunegg/onedrive/archive/refs/tags/v2.4.17.tar.gz -O /tmp/onedrive.tar.gz
RUN tar -zxvf /tmp/onedrive.tar.gz
RUN mv onedrive-2.4.17 /usr/src/onedrive

RUN cd /usr/src/onedrive/ && \
    if [ ${TARGETPLATFORM} = 'linux/amd64' ]; then ./configure; fi && \
    if [ ${TARGETPLATFORM} = 'linux/arm64' ]; then ./configure DC=/ldc2-1.17.0-linux-aarch64/bin/ldmd2; fi && \
    make clean && \
    make && \
    make install

FROM debian:stretch-slim
RUN apt update && \
    apt install -y gosu libcurl3 libsqlite3-0 && \
    rm -rf /var/*/apt && \
    mkdir -p /onedrive/conf /onedrive/data

COPY --from=0 /usr/src/onedrive/contrib/docker/entrypoint.sh /
COPY --from=0 /usr/local/bin/onedrive /usr/local/bin/

ENTRYPOINT ["/entrypoint.sh"]
