#!/bin/bash

set -e

ME=$(basename $0)

NGINX_BASICAUTH_FILES_PATH=${NGINX_BASICAUTH_FILES_PATH:-/etc/nginx/conf.d}
NGINX_BASICAUTH_ENV_PREFIX=${NGINX_BASICAUTH_ENV_PREFIX:-BASICAUTH}

if [[ ! -w "${NGINX_BASICAUTH_FILES_PATH}" ]]; then
  echo >&3 "$ME: error: ${NGINX_BASICAUTH_FILES_PATH} is not writable"
  exit 0
fi

basicauth=$(env | sort | grep -Eo '^'${NGINX_BASICAUTH_ENV_PREFIX}'_([A-Z0-9]{1,})((_[0-9]{1,}_)|_)(USER|PASS)=.+$' || true)
names="$(echo "${basicauth}" | sed 's/^'${NGINX_BASICAUTH_ENV_PREFIX}'_\([A-Z0-9]*\)_\(.*\)$/\1/g' | uniq)"
for name in ${names}; do
  prefixes="$(echo "${basicauth}" | grep -Eo '^'${NGINX_BASICAUTH_ENV_PREFIX}'_'${name}'((_[0-9]{1,}_)|_)' | uniq)"
  htpasswd_file="${NGINX_BASICAUTH_FILES_PATH}/$(echo "${name}" | tr '[:upper:]' '[:lower:]').htpasswd"
  for prefix in ${prefixes}; do
    user="$(env | grep -Eo '^'${prefix}'USER=.+' | sed 's/^'${prefix}'USER=//g')"
    pass="$(env | grep -Eo '^'${prefix}'PASS=.+' | sed 's/^'${prefix}'PASS=//g')"
    if [[ -n "${user}" ]] && [[ -n "${pass}" ]]; then
      echo "$(htpasswd -bn "${user}" "${pass}")" >> "${htpasswd_file}"
      echo >&3 "$ME: Adding a user '${user}' on ${htpasswd_file}"
    fi
  done
done
