#!/bin/bash

set -eu

LOG_FILE="$PWD/log/$(date +'%Y-%m-%d_%H-%M-%S').log"

main() {
  detect_os

  if [ "$PLATFORM" != 'linux' ] && [ "$PLATFORM" != 'mac' ]; then
    abort 'このOSは対応していません'
  fi

  if [ "$PLATFORM" = 'linux' ]; then
    detect_distribution
  fi

  setup

  exit 0
}

detect_os() {
  if [ "$(uname)" == "Darwin" ]; then
    PLATFORM=mac
  elif [ "$(uname -s)" == "MINGW" ]; then
    PLATFORM=windows
  elif [ "$(uname -s)" == "Linux" ]; then
    PLATFORM=linux
  else
    PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

detect_distribution() {
  if [ -e /etc/lsb-release ]; then
    DISTRIBUTION="$(grep ^NAME= /etc/os-release)"
    DISTRIBUTION=${DISTRIBUTION#NAME=}
    DISTRIBUTION=${DISTRIBUTION//\"/}
    log "DISTRIBUTION: $DISTRIBUTION"

    DISTRIBUTION_VERSION_ID="$(grep ^VERSION_ID= /etc/os-release)"
    DISTRIBUTION_VERSION_ID=${DISTRIBUTION_VERSION_ID#VERSION_ID=}
    DISTRIBUTION_VERSION_ID=${DISTRIBUTION_VERSION_ID//\"/}
    log "DISTRIBUTION_VERSION_ID: $DISTRIBUTION_VERSION_ID"

    DISTRIBUTION_ID_LIKE="$(grep ^ID_LIKE= /etc/os-release)"
    DISTRIBUTION_ID_LIKE=${DISTRIBUTION_ID_LIKE#ID_LIKE=}
    log "DISTRIBUTION_ID_LIKE: $DISTRIBUTION_ID_LIKE"

    UBUNTU_CODENAME="$(grep ^UBUNTU_CODENAME= /etc/os-release)"
    UBUNTU_CODENAME=${UBUNTU_CODENAME#UBUNTU_CODENAME=}
    log "UBUNTU_CODENAME: $UBUNTU_CODENAME"
  elif [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    DISTRIBUTION=debian
  elif [ -e /etc/redhat-release ]; then
    if [ -e /etc/oracle-release ]; then
      DISTRIBUTION=oracle
    else
      DISTRIBUTION=redhat
    fi
  elif [ -e /etc/fedora-release ]; then
    DISTRIBUTION=fedora
  elif [ -e /etc/arch-release ]; then
    DISTRIBUTION=arch
  else
    DISTRIBUTION="Unknown Distribution"
    abort "Your distribution is not supported."
  fi
}

abort() {
  printf "%s\n" "$@"
  exit 1
}

log() {
  mkdir -p "$PWD/log"
  echo "$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] | $1" >> "$LOG_FILE"
}

is_exists() {
  which "$1" >/dev/null 2>&1
  return $?
}

setup_brew() {
  # インストーラでプラットフォームの差分を吸収している
  echo "brew is not installed"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

SOFTWARE_LIST=(
  brew
)

setup() {
  for software in "${SOFTWARE_LIST[@]}"; do
    check_confirm "$software"
  done
}

# only install if not installed
check_confirm() {
  INSTALLED=false

  # fish shell: plugins
  case $1 in
    fisher ) [ -e "$HOME/.config/fish/functions/fisher.fish" ] && INSTALLED=true ;;
    z      ) [ -e "$HOME/.config/fish/conf.d/z.fish" ]         && INSTALLED=true ;;
    omf    ) [ -e "$HOME/.config/fish/conf.d/omf.fish" ]       && INSTALLED=true ;;
    bd     ) [ -e "$HOME/.config/fish/functions/bd.fish" ]     && INSTALLED=true ;;
    bass   ) [ -e "$HOME/.config/fish/functions/bass.fish" ]   && INSTALLED=true ;;
  esac

  if is_exists "$1"; then
      INSTALLED=true
  elif is_exists brew; then
    if [ "$(brew list | grep -c "^$1@*.*$")" -gt 0 ]; then
      INSTALLED=true
    fi
  fi

  if "${INSTALLED}"; then
    log "$1 is already installed"
    return
  fi

  if confirm "$1 をインストールします。よろしいですか？"; then
    case $1 in
      brew ) setup_brew ;;
    esac
  else
    log "do not install $1."
  fi
}

versions() {
  for software in "${SOFTWARE_LIST[@]}"; do
    if is_exists "$software"; then
      case $software in
        brew ) log "brew: $(brew -v | head -n 1)" ;;
      esac
    fi
  done
}

if [ "$#" == 0 ]; then
  main
elif [ "$1" == "versions" ]; then
  versions
fi
