#!/bin/bash


# shellcheck disable=SC1091
. gettext.sh

export TEXTDOMAIN=checkpkg
export TEXTDOMAINDIR=/usr/share/locale

check_version() {
  local local_version pkg_version pkg_name

  local_version="$1"
  pkg_version="$2"
  pkg_name="$3"

  if [ -z "$local_version" ]; then
    gather "$(gettext "Package %b%s %bnot installed%b. Its last version is %b%s%b.\n")" "$WC" "$pkg_name" "$CC" "$NC" "$GC" "$pkg_version" "$NC"
  elif [ ! "$local_version" == "$pkg_version" ]; then
    gather "$(gettext "Package %b%s %boutdated%b [%b%s%b -> %b%s%b].\n")" "$WC" "$pkg_name" "$CC" "$NC" "$GC" "$local_version" "$NC" "$GC" "$pkg_version" "$NC"
  else
    gather "$(gettext "Package %b%s %bup to date%b [%b%s%b].\n")" "$WC" "$pkg_name" "$CC" "$NC" "$GC" "$local_version" "$NC"
  fi
}

get_request_code() {
  local req_info req_status

  req_info="$1"
  req_status=$(tail -n1 <<<"$req_info")

  echo "$req_status"
}

get_pages_number() {
  local req_info

  req_info="$1"

  pages_number=$(grep -E "Page\s+[0-9]+\s+of\s+[0-9]+.</p>" <<<"$req_info" | \
  head -n1 | \
  sed 's/.\+[0-9]\+\s\+of\s\+\([0-9]\).\+/\1/g')

  echo "$pages_number"
}

match_package_info() {
  local pkg pkg_req pkg_info

  pkg="$1"
  pkg_req="$2"

  pkg_info=$(echo "$pkg_req" | \
  sed '/^\s*$/d' | \
  grep -E "<td><a\s*href=\"\/packages\/\w+\/($ARCH|any)\/.*\"[^>]*>$pkg<\/a><\/td>" -A1 | \
  sed 's/\(\s*\|<[^>]\+>\)//g' | \
  head -n 2)

  echo "$pkg_info"
}

get_package_info() {
  local pkg pkg_req pkg_req_status pkg_req_pages pkg_info

  pkg="$1"

  pkg_req=$(curl -s -w '%{http_code}' "$BASE_URL$ARCH_URL$ARCH$REPO_URL$Q_URL$pkg")
  pkg_req_status=$(get_request_code "$pkg_req")
  pkg_req_pages=$(get_pages_number "$pkg_req")

  pkg_req_pages=${pkg_req_pages:-1}

  pkg_info=$(match_package_info "$pkg" "$pkg_req")

  for i in $(seq 2 "$pkg_req_pages"); do
    if [ -z "$pkg_info" ] && [ "$pkg_req_status" -eq 200 ]; then
      pkg_req=$(curl -s -w '%{http_code}' "$BASE_URL$ARCH_URL$ARCH$REPO_URL$Q_URL$pkg$PAGE_URL$i")
      pkg_req_status=$(get_request_code "$pkg_req")

      pkg_info=$(match_package_info "$pkg" "$pkg_req")
    fi
  done

  echo "$pkg_info"
}

gather() {
  local text

  text="$1"; shift
  # shellcheck disable=SC2059
  printf "$text" "$@"
}

print_array() {
  local IFS=,; gather "$(gettext "Checking %s ...\n\n")" "$*"
}

show_info() {
  local pkg pkg_info pkg_name pkg_version local_version

  pkg="$1"

  pkg_info=$(get_package_info "$pkg")

  pkg_name=$(head -n1 <<<"$pkg_info")
  pkg_version=$(tail -n1 <<<"$pkg_info")

  if [ -n "$pkg_name" ]; then
    local_version=$(pacman -Q "$pkg" 2>/dev/null | awk '{ print $2 }')
    check_version "$local_version" "$pkg_version" "$pkg_name"
  else
    gather "$(gettext "Package %b%s %bnot found%b.\n")" "$WC" "$pkg" "$CC" "$NC"
  fi
}

main() {
  local pkg

  print_array "$@"

  for pkg in "$@"; do
    if [ -z "$ORDERED" ]; then
      show_info "$pkg" &
    else
      show_info "$pkg"
    fi
  done

  wait
}

initial_checks() {
  if ! which pacman >/dev/null; then
    (gettext 'pacman is not installed.'; echo;) >&2
    exit 1
  fi

  [ ${#packages[@]} -eq 0 ] && exit 1
}

set_global_variables() {
  [ -n "$COMMUNITY_TESTING" ] && REPO_URL+="&repo=Community-Testing"
  [ -n "$MULTILIB_TESTING" ] && REPO_URL+="&repo=Multilib-Testing"
  [ -n "$TESTING" ] && REPO_URL+="&repo=Testing"
}

ARCH="${ARCH:-$(uname -m)}"

BASE_URL="https://www.archlinux.org/packages/search/json"
ARCH_URL="&arch=any&arch=$ARCH"
REPO_URL="&repo=Community&repo=Core&repo=Extra&repo=Multilib"
Q_URL="&q="
PAGE_URL="&page="

GC="\033[1;32m"  # green
CC="\033[1;36m"  # cyan
WC="\033[1;97m"  # white
NC="\033[0m"     # no color

set_global_variables

typeset -a packages

if [ ! -t 0 ]; then
  while read -r pkg; do
    packages+=( "$pkg" )
  done
fi

while [ -n "$1" ]; do
  case "$1" in
    -o|--ordered)
      ORDERED=1; shift;;
    *)
      packages+=( "$1" ); shift;;
  esac
done

initial_checks

main "${packages[@]}"
