#!/bin/bash -x

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
CLIENT_VERSION=0.1

. "functions/redis.sh"


while getopts g:P:H:p:ha opt; do
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
		a)
			REDIS_ARRAY=1
			;;
		h)
			echo ""
			echo "USAGE:"
			echo "	$0 [-g <var>] [-p <password>] [-H <hostname>] [-P <port>]"
			echo ""
			exit 1
			;;
	esac
done
	
exec {FD}<> /dev/tcp/$REDIS_HOST/$REDIS_PORT

if [[ ! -z $REDIS_PW ]]; then
	redis_compose_cmd "AUTH $REDIS_PW" >&$FD
fi

if [[ ! -z $REDIS_GET ]]; then
	if [[ $REDIS_ARRAY -eq 1 ]]; then
		redis_get_array $REDIS_GET >&$FD
		redis_read $FD
	else	
		redis_get_var $REDIS_GET >&$FD
		redis_read $FD
	fi

	exec {FD}>&-
	exit 0
fi

while read line
do
        REDIS_TODO=$line
done < /dev/stdin

if [[ $REDIS_ARRAY -eq 1 ]]; then
	#we are treating the stdin as array
	ARRAY_NAME=$(printf %b "$REDIS_TODO" | cut -f1 -d"=")
	typeset -a temparray=$(printf %b "$REDIS_TODO" | cut -f2- -d"=")
	redis_set_array $ARRAY_NAME temparray[@] >&$FD
	redis_read $FD
	exit 0
fi
KEYNAME=$(printf %b "$REDIS_TODO" | cut -f1 -d"=")
KEYVALUE=$(printf %b "$REDIS_TODO" | cut -f2- -d"=")

redis_set_var $KEYNAME $KEYVALUE >&$FD
printf %b "$(redis_read $FD)"

exec {FD}>&-
