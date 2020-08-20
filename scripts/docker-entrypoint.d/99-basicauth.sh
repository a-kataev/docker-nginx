#!/bin/sh

set -e

basicauth_filepath=${BASICAUTH_FILESPATH:-/etc/nginx/conf.d}
basicauth_envprefix=${BASICAUTH_ENVPREFIX:-BASICAUTH}

names="$(env | sort | grep -Eo '^'${basicauth_envprefix}'_([A-Z0-9]{1,})_' | \
  sed 's/^'${basicauth_envprefix}'_\([A-Z0-9]*\)_/\1/g' | uniq)"
for name in ${names}; do
  prefixes="$(env | sort | grep -Eo '^'${basicauth_envprefix}'_'${name}'_([0-9]{1,})_(USER|PASS)=.+' | \
    grep -Eo '^'${basicauth_envprefix}'_'${name}'_([0-9]{1,})_' | uniq)"
  name="$(echo "${name}" | tr '[:upper:]' '[:lower:]').htpasswd"
  for prefix in ${prefixes}; do
    user="$(env | grep -Eo '^'${prefix}'USER=.+' | sed 's/^'${prefix}'USER=//g')"
     pass="$(env | grep -Eo '^'${prefix}'PASS=.+' | sed 's/^'${prefix}'PASS=//g')"
    if [[ -n "${user}" ]] && [[ -n "${pass}" ]]; then
      echo "$(htpasswd -bn "${user}" "${pass}")" >> "${basicauth_filepath}/${name}"
    fi
  done
done
