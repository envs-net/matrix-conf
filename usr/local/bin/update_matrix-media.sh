#!/usr/bin/env bash

[ "$(id -u)" -ne 0 ] && printf 'Please run as root!\n' && exit 1

ver="$1"
[ -z "$ver" ] && printf 'use: %s <version>\n' "${0##*/}" && exit 1

systemctl stop matrix-media.service

wget -O /opt/matrix-media-repo/media_repo-linux-x64 https://github.com/turt2live/matrix-media-repo/releases/download/v"$ver"/media_repo-linux-x64
chmod +x /opt/matrix-media-repo/media_repo-linux-x64

wget -O /opt/matrix-media-repo/config.sample.yaml https://raw.githubusercontent.com/turt2live/matrix-media-repo/master/config.sample.yaml

systemctl start matrix-media.service

exit 0
