ARG NGINX_VERSION=1.19.6
ARG NJS_VERSION=0.5.0
ARG NGX_CACHE_PURGE_VERSION=2.3

FROM debian:10.7-slim

ARG NGINX_VERSION
ARG NJS_VERSION
ARG NGX_CACHE_PURGE_VERSION
ARG PKG_RELEASE=1~buster

ENV NGINX_VERSION=${NGINX_VERSION}-${PKG_RELEASE} \
  NJS_VERSION=${NGINX_VERSION}+${NJS_VERSION}-${PKG_RELEASE} \
  NGX_CACHE_PURGE_VERSION=${NGX_CACHE_PURGE_VERSION}

RUN set -x && \
#
  apt-get update && \
  apt-get install -y --no-install-recommends git curl && \
  apt-get install -y --no-install-recommends apt-transport-https ca-certificates dpkg-dev && \
#
  apt-get install -y --no-install-recommends gnupg1 && \
  curl -s https://nginx.org/keys/nginx_signing.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true apt-key add && \
  rm -rf /var/lib/apt/lists/* && \
#
  echo 'deb-src https://nginx.org/packages/mainline/debian/ buster nginx' > /etc/apt/sources.list.d/nginx.list && \
  apt-get update && \
#
  NGINX_PACKAGES=" \
    nginx=${NGINX_VERSION} \
    nginx-module-xslt=${NGINX_VERSION} \
    nginx-module-geoip=${NGINX_VERSION} \
    nginx-module-image-filter=${NGINX_VERSION} \
    nginx-module-njs=${NJS_VERSION} \
  " && \
  apt-get build-dep -y ${NGINX_PACKAGES} && \
#
  cd /usr/src && \
  apt-get source ${NGINX_PACKAGES} && \
#
  NGINX_DIR="/usr/src/nginx-$(echo ${NGINX_VERSION} | sed 's/^\(.*\)-\([0-9]*\)\~buster$/\1/')" && \
  MODULES_DIR="${NGINX_DIR}/debian/modules" && \
# ngx-brotli
  MODULE_BROTLI_DIR="${MODULES_DIR}/ngx-brotli" && \
  git clone https://github.com/google/ngx_brotli.git "${MODULE_BROTLI_DIR}" && \
  (cd "${MODULE_BROTLI_DIR}"; git submodule update --init) && \
  sed -i "/LDFLAGS /a WITH_NGX_BROTLI := --add-module=${MODULE_BROTLI_DIR}" "${NGINX_DIR}/debian/rules" && \
  sed -i 's/^\s\+CFLAGS=.*$/& $(WITH_NGX_BROTLI)/g' "${NGINX_DIR}/debian/rules" && \
# ngx-cache-purge
  MODULE_CACHE_PURGE_DIR="${MODULES_DIR}/ngx-cache-purge-${NGX_CACHE_PURGE_VERSION}" && \
  mkdir -p "${MODULE_CACHE_PURGE_DIR}" && \
  curl -sL "https://codeload.github.com/FRiCKLE/ngx_cache_purge/tar.gz/${NGX_CACHE_PURGE_VERSION}" | \
    tar xz -C "${MODULE_CACHE_PURGE_DIR}" --strip-components=1 && \
  sed -i "/LDFLAGS /a WITH_NGX_CACHE_PURGE := --add-module=${MODULE_CACHE_PURGE_DIR}" "${NGINX_DIR}/debian/rules" && \
  sed -i 's/^\s\+CFLAGS=.*$/& $(WITH_NGX_CACHE_PURGE)/g' "${NGINX_DIR}/debian/rules" && \
#
  DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" apt-get source --compile ${NGINX_PACKAGES} && \
#
  ls -lah *.deb && \
#
  mkdir nginx-deb && \
  mv *.deb nginx-deb && \
  find nginx-deb -name '*-dbg_*.deb' -exec rm {} + && \
#
  ls -lah nginx-deb/*.deb && \
#
  (cd nginx-deb; dpkg-scanpackages . > Packages)


FROM debian:10.7-slim

LABEL maintainer="Alex Kataev <dlyavsehpisem@gmail.com>"

ARG NGINX_VERSION

ENV NGINX_VERSION=${NGINX_VERSION}

COPY --from=0 /usr/src/nginx-deb /usr/src/nginx-deb/

RUN set -x && \
#
  ls -alh /usr/src/nginx-deb && \
#
  apt-get update && \
  apt-get install -y --no-install-recommends curl ca-certificates vim net-tools procps less tree openssl apache2-utils && \
#
  rm -rf /var/lib/apt/lists/* && \
  echo "deb [ trusted=yes ] file:///usr/src/nginx-deb ./" > /etc/apt/sources.list.d/nginx.list && \
  apt-get -o Acquire::GzipIndexes=false update && \
  apt-get install -y --no-install-recommends nginx nginx-module-* && \
#
  rm -rf /tmp/* /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list /usr/src/* && \
#
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  mkdir /docker-entrypoint.d

EXPOSE 80

STOPSIGNAL SIGQUIT

COPY scripts/docker-entrypoint.sh /
COPY scripts/docker-entrypoint.d/ /docker-entrypoint.d

RUN set -x && \
  chmod +x /docker-entrypoint.sh /docker-entrypoint.d/*.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
