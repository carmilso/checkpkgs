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

get_package_version() {
  local pkg pkg_info pkg_version pkg_rel

  pkg="$1"

  pkg_info=$(curl -s "$QUERY_URL$pkg" | jq -c '.results[0]')
  pkg_version=$(jq '.pkgver' <<<"$pkg_info")
  pkg_rel=$(jq '.pkgrel' <<<"$pkg_info")

  echo "$pkg_version-$pkg_rel" | tr -d '"'
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
  local pkg pkg_info pkg_version local_version

  pkg="$1"

  pkg_version=$(get_package_version "$pkg")

  if [[ "$pkg_version" =~ "null" ]]; then
    gather "$(gettext "Package %b%s %bnot found%b.\n")" "$WC" "$pkg" "$CC" "$NC"
  else
    local_version=$(pacman -Q "$pkg" 2>/dev/null | awk '{ print $2 }')
    check_version "$local_version" "$pkg_version" "$pkg"
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

set_testing_repositories() {
  [ -n "$COMMUNITY_TESTING" ] && REPO_URL+="&repo=Community-Testing"
  [ -n "$MULTILIB_TESTING" ] && REPO_URL+="&repo=Multilib-Testing"
  [ -n "$TESTING" ] && REPO_URL+="&repo=Testing"
}

ARCH="${ARCH:-$(uname -m)}"

BASE_URL="https://www.archlinux.org/packages/search/json/"
ARCH_URL="arch=any&arch=$ARCH"
REPO_URL="repo=Community&repo=Core&repo=Extra&repo=Multilib"
NAME_URL="name="

GC="\033[1;32m"  # green
CC="\033[1;36m"  # cyan
WC="\033[1;97m"  # white
NC="\033[0m"     # no color

set_testing_repositories

QUERY_URL="$BASE_URL?$ARCH_URL&$REPO_URL&$NAME_URL"

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
