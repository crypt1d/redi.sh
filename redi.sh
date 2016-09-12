#!/bin/bash

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
CLIENT_VERSION=0.2


function redis_read_str() {
        typeset REDIS_STR="$@"
        printf %b "$REDIS_STR" | cut -f2- -d+ | tr -d '\r'
}

function redis_read_err() {
        typeset REDIS_ERR="$@"
        printf %s "$REDIS_ERR" | cut -f2- -d-
        exit 1
}

function redis_read_int() {
        typeset -i OUT_INT=$(printf %s "$1" | tr -d : | tr -d '\r')
        printf %b "$OUT_INT"
}

function redis_read_bulk() {
        typeset -i BYTE_COUNT=$1
        typeset -i FILE_DESC=$2
        if [[ $BYTE_COUNT -lt 0 ]]; then
                echo ERROR: Null or incorrect string size returned. >&2
		exec {FILE_DESC}>&-
                exit 1
        fi

        echo $(dd bs=1 count=$BYTE_COUNT status=noxfer <&$FILE_DESC 2>/dev/null)
        dd bs=1 count=2 status=noxfer <&$FILE_DESC 1>/dev/null 2>&1 # we are removing the extra character \r
}

function redis_read() {

typeset -i FILE_DESC=$1

if [[ $# -eq  2 ]]; then
	typeset -i PARAM_COUNT=$2
	typeset -i PARAM_CUR=1
fi

while read -r socket_data
do
        typeset first_char
        first_char=$(printf %b "$socket_data" | head -c1)

        case $first_char in
                '+')
                        redis_read_str "$socket_data"
                        ;;
                '-')
                        redis_read_err "$socket_data"
                        ;;
                ':')
                        redis_read_int "$socket_data"
                        ;;
                '$')
                        bytecount=$(printf %b "$socket_data" | cut -f2 -d$ | tr -d '\r')
                        redis_read_bulk "$bytecount" "$FILE_DESC"
                        ;;
                '*')
                        paramcount=$(printf %b "$socket_data" | cut -f2 -d* | tr -d '\r')
			redis_read "$FILE_DESC" "$paramcount"
                        ;;
        esac

if [[ ! -z $PARAM_COUNT ]]; then
	if [[ $PARAM_CUR -lt $PARAM_COUNT ]]; then
		((PARAM_CUR+=1))
		continue
	else
       		break
	fi
else
	break
fi

done<&"$FILE_DESC"

}

function redis_compose_cmd() {
    typeset REDIS_PASS="$1"
    printf %b "*2\r\n\$4\r\nAUTH\r\n\$${#REDIS_PASS}\r\n$REDIS_PASS\r\n"
}

function redis_get_var() {
	typeset REDIS_VAR="$@"
	printf %b "*2\r\n\$3\r\nGET\r\n\$${#REDIS_VAR}\r\n$REDIS_VAR\r\n"
}

function redis_set_var() {
	typeset REDIS_VAR="$1"
	shift
	typeset REDIS_VAR_VAL="$@"
	printf %b "*3\r\n\$3\r\nSET\r\n\$${#REDIS_VAR}\r\n$REDIS_VAR\r\n\$${#REDIS_VAR_VAL}\r\n$REDIS_VAR_VAL\r\n"
}

function redis_get_array() {
	typeset REDIS_ARRAY="$1"
	printf %b "*4\r\n\$6\r\nLRANGE\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n\$1\r\n0\r\n\$2\r\n-1\r\n"
}

function redis_set_array() {
	typeset REDIS_ARRAY="$1"
	typeset -a REDIS_ARRAY_VAL=("${!2}")

	printf %b "*2\r\n\$3\r\nDEL\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n"
	for i in "${REDIS_ARRAY_VAL[@]}"
	do
		printf %b "*3\r\n\$5\r\nRPUSH\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n\$${#i}\r\n$i\r\n"
	done
}

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
			echo
			echo USAGE:
			echo "	$0 [-a] [-g <var>] [-p <password>] [-H <hostname>] [-P <port>]"
			echo
			exit 1
			;;
	esac
done


exec {FD}<> /dev/tcp/"$REDIS_HOST"/"$REDIS_PORT"

if [[ ! -z $REDIS_PW ]]; then
	redis_compose_cmd "$REDIS_PW" >&$FD
    redis_read $FD 1>/dev/null 2>&1
fi

if [[ ! -z $REDIS_GET ]]; then
	if [[ $REDIS_ARRAY -eq 1 ]]; then
		redis_get_array "$REDIS_GET" >&$FD
		IFS=$'\n'
		typeset -a OUTPUT_ARRAY

		for i in $(redis_read $FD)
		do
			OUTPUT_ARRAY+=($i)
		done

		typeset | grep ^OUTPUT_ARRAY | sed s/OUTPUT_ARRAY/"$REDIS_GET"/

	else
		redis_get_var "$REDIS_GET" >&$FD
		redis_read $FD
	fi

	exec {FD}>&-
	exit 0
fi

while read -r line
do
        REDIS_TODO=$line
done </dev/stdin

if [[ $REDIS_ARRAY -eq 1 ]]; then
	ARRAY_NAME=$(printf %b "$REDIS_TODO" | cut -f1 -d=)
	typeset -a temparray=$(printf %b "$REDIS_TODO" | cut -f2- -d=)
	redis_set_array "$ARRAY_NAME" temparray[@] >&$FD
	redis_read $FD 1>/dev/null 2>&1
	exit 0
fi

KEYNAME=$(printf %b "$REDIS_TODO" | cut -f1 -d=)
KEYVALUE=$(printf %b "$REDIS_TODO" | cut -f2- -d=)

redis_set_var "$KEYNAME" "$KEYVALUE" >&$FD
redis_read $FD 1>/dev/null 2>&1

exec {FD}>&-
