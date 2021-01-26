#!/bin/sh

set -eu

ROOT_DIR=/home/user/app

mkdir -p "$ROOT_DIR/tmp"
chown -R user:user "$ROOT_DIR/tmp"

export HOME=/home/user

echo "**** GOSU user $* ..."
exec gosu user "$@"

