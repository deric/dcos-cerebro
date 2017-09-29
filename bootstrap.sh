#!/bin/bash
export LC_ALL=C
#
function -h {
  cat <<USAGE
   USAGE: Generates Cerebro config

   -v / --verbose  debugging output

USAGE
}; function --help { -h ;}

function msg { out "$*" >&1 ;}
function out { printf '%s\n' "$*" ;}
function err { local x=$? ; msg "$*" ; return $(( $x == 0 ? 1 : $x )) ;}

function main {
  local verbose=false
  while [[ $# -gt 0 ]]
  do
    case "$1" in                                      # Munging globals, beware
      -v|--verbose)         verbose=true; shift 1 ;;
      *)                    err 'Argument error. Please see help: -h' ;;
    esac
  done
  if [[ $verbose == true ]]; then
    set -ex
  fi
  common_config
  auth_config
  servers_config
}

function common_config {
  CEREBRO_REST_HIST_SIZE="${CEREBRO_REST_HIST_SIZE:-50}"
  CEREBRO_SECRET="${CEREBRO_SECRET:-$(date +%s | sha256sum | base64 | head -c 64 ; echo)}"
  CEREBRO_DB_DRIVER="${CEREBRO_DB_DRIVER:-org.sqlite.JDBC}"
  CEREBRO_DB_URL="${CEREBRO_DB_URL:-jdbc:sqlite:./cerebro.db}"

  cat > "application.conf" <<EOF
# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
secret = "${CEREBRO_SECRET}"

# Application base path
basePath = "/"

# Defaults to RUNNING_PID at the root directory of the app.
# To avoid creating a PID file set this value to /dev/null
#pidfile.path = "/var/run/cerebro.pid"
pidfile.path=/dev/null

# Rest request history max size per user
rest.history.size = ${CEREBRO_REST_HIST_SIZE} // defaults to 50 if not specified

# Path of local database file
slick.dbs.default.db.driver = "${CEREBRO_DB_DRIVER}"
slick.dbs.default.db.url = "${CEREBRO_DB_URL}"
EOF
}

function auth_config {
  CEREBRO_AUTH="${CEREBRO_AUTH:-none}"
  local nl=$'\n\t'
  if [ ! -z "${CEREBRO_AUTH}" ] && [ "${CEREBRO_AUTH}" != "none" ]; then
    local auth_conf=""
    if [[ "${CEREBRO_AUTH}" == "ldap" ]]; then
      auth_conf+="url = \"${CEREBRO_LDAP_URL}\"$nl"
      auth_conf+="base-dn = \"${CEREBRO_LDAP_BASE}\"$nl"
      auth_conf+="method = \"${CEREBRO_LDAP_METHOD}\"$nl"
      auth_conf+="user-domain = \"${CEREBRO_LDAP_DOMAIN}\"$nl"
    elif [[ "${CEREBRO_AUTH}" == "basic" ]]; then
      auth_conf+="user = \"${CEREBRO_BASIC_USER}\"$nl"
      auth_conf+="password = \"${CEREBRO_BASIC_PASS}\"$nl"
    else
      err "Authentication method '${CEREBRO_AUTH}' is not supported"
    fi

  cat >> "application.conf" <<EOF
# Authentication
auth = {
  # Example of LDAP authentication
  type: ${CEREBRO_AUTH}
    settings: {
        ${auth_conf}
    }
}
EOF
  fi
}

function servers_config {
  local servers=""
  local nl=$'\n'
  local t=$'\t'
  local name
  local clust=$(seq 1 9)
  for i in $clust[@];
  do
    local var="ES_$i"
    if [ ! -z "${!var}" ]; then
      if [ $i -gt 1 ]; then
        servers+=",$nl"
      fi
      servers+="{$nl"
      servers+="$t host = \"${!var}\""
      name="ES_${i}_NAME"
      if [ ! -z "${!name}" ]; then
        servers+="$nl$t name = \"${!name}\""
      fi
      name="ES_${i}_USER"
      if [ ! -z "${!name}" ]; then
        servers+="$nl$t auth = {"
        servers+="$nl$t$t username = ${!name}"
        name="ES_${i}_PASS"
        if [ ! -z "${!name}" ]; then
          servers+="$nl$t$t password = ${!name}"
        fi
        servers+="$nl$t }"
      fi
      servers+="$nl  }"
    fi
  done

  if [ ! -z "${servers}" ]; then
    cat >> "application.conf" <<EOF
# A list of known hosts
hosts = [
  ${servers}
]
EOF
  fi
}

if [[ ${1:-} ]] && declare -F | cut -d' ' -f3 | fgrep -qx -- "${1:-}"
then
  case "$1" in
    -h|--help) : ;;
    *) ;;
  esac
  "$@"
else
  main "$@"
fi
