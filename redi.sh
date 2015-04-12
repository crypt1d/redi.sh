#!/bin/bash

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

. "functions/redis.sh"

function set_from_pipe() {
	typeset KEYNAME=$(echo "$@" | awk -F\= '{print $1}')
	typeset KEYVALUE=$(echo "$@" | awk -F\= '{print $2}')

	redis_compose_cmd "SET $KEYNAME $KEYVALUE" >&3
}

function read_from_pipe() {
	while read line
	do
		echo -ne $line
	done < /dev/stdin
}

exec 3<> /dev/tcp/$REDIS_HOST/$REDIS_PORT

redis_compose_cmd "GET test" >&3

echo "$(redis_read)"

exec 3<&-
exec 3>&-
