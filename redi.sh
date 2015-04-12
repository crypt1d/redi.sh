#!/bin/bash

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

. "functions/redis.sh"


while getopts g:P:h:p opt; do
	case $opt in
		p)
			REDIS_PW=${OPTARG}
			;;
		H)
			REDIS_HOST=${OPTARG}
			;;
		P)
			REDIS_PORT=${OPTARG}
			;;
		g)
			REDIS_GET=${OPTARG}
			;;
	esac
done
	
exec 3<> /dev/tcp/$REDIS_HOST/$REDIS_PORT

if [[ ! -z $REDIS_PW ]]; then
	redis_compose_cmd "AUTH $REDIS_PW" >&3
fi

if [[ ! -z $REDIS_GET ]]; then
	redis_compose_cmd "GET $REDIS_GET" >&3
	redis_read
	exec 3<&-
	exec 3>&-
	exit 0
fi

while read line
do
        REDIS_TODO=$line
done < /dev/stdin

read KEYNAME KEYVALUE <<<$(echo "$REDIS_TODO" | awk -F\= '{print $1,$2}')

redis_compose_cmd "SET $KEYNAME $KEYVALUE" >&3
echo "$(redis_read)"

exec 3<&-
exec 3>&-
