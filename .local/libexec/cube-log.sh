#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube log" ''
	msg -- 'Options:'
	disp    :usage			--help -h
	disp    VERSION			--version
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

LOG_TTY=$(basename `tty`)

cat <<HERE
This is a WIP and only outputs what you need to do to make terminal logging work

Add a new conf to rsyslog in /etc/rsyslog.d called 90-cube-env.conf with this content

local7.*        /dev/pts/${LOG_TTY}

Future version of this will use something like this to make the change for you

sed -i "s,\(local7.\+/dev/pts/\).\+,\1${LOG_TTY}," /etc/rsyslog.d/90-cube-env.conf

Then test it with this

logger --priority local7.info "This is a lame log entry"
HERE
