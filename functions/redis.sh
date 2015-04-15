#!/bin/bash

function redis_read_str() {
        typeset REDIS_STR="$@"
        printf %b "$REDIS_STR" | cut -f2- -d"+" | tr -d '\r'
}

function redis_read_err() {
        typeset REDIS_ERR="$@"
        printf %s "$REDIS_ERR" | cut -f2- -d"-"
        exit 1
}

function redis_read_int() {
        typeset -i OUT_INT=$(printf %s $1 | tr -d '\:' | tr -d '\r')
        printf %b "$OUT_INT"
}

function redis_read_bulk() {
        typeset -i BYTE_COUNT=$1
	typeset -i FILE_DESC=$2
        if [[ $BYTE_COUNT -lt 0 ]]; then
                echo "ERROR: Null or incorrect string size returned." >&2
		exec {FILE_DESC}>&-
                exit 1
        fi

#	((BYTE_COUNT+=1))

        echo $(dd bs=1 count=$BYTE_COUNT status=noxfer <&$FILE_DESC 2>/dev/null)
	dd bs=1 count=2 status=noxfer <&$FILE_DESC 1>/dev/null 2>&1
}

function redis_read_array() {
        typeset -i PARAM_COUNT=$1
	typeset -i FILE_DESC=$2
        if [[ $PARAM_COUNT -lt 0 ]]; then
                echo "ERROR: Null or incorrect array size returned." >&2
                exit 1
        fi

        typeset -i CUR_PARAM=1
        while read line
        do
                redis_read $FILE_DESC
                ((CUR_PARAM+=1))
                if [[ $CUR_PARAM -gt $PARAM_COUNT ]]; then
                        break
                fi

        done<&$FILE_DESC

}

function redis_read() {

typeset -i FILE_DESC=$1

if [[ $# -eq  2 ]]; then
	typeset -i PARAM_COUNT=$2
	typeset -i PARAM_CUR=1
fi

while read socket_data
do
        typeset first_char=$(printf %b "$socket_data" | head -c1)

        case $first_char in
                "+")
                        #echo "This is a simple string."
                        redis_read_str "$socket_data"
                        ;;
                "-")
                        #echo "This is an error."
                        redis_read_err "$socket_data"
                        ;;
                ":")
                        #echo "This is an integer."
                        redis_read_int $socket_data
                        ;;
                "\$")
                        #echo "This is a bulk string."
                        bytecount=$(printf %b "$socket_data" | cut -f2 -d"\$" | tr -d '\r')
                        redis_read_bulk $bytecount $FILE_DESC
                        ;;
                "*")
                        #echo "This is an array."
                        paramcount=$(printf %b "$socket_data" | cut -f2 -d"*" | tr -d '\r')
                        #redis_read_array $paramcount $FILE_DESC
			redis_read $FILE_DESC $paramcount
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

done<&$FILE_DESC

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
#	printf %b "*4\r\n\$6\r\nLRANGE\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n:0\r\n:-1\r\n"
	printf %b "*4\r\n\$6\r\nLRANGE\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n\$1\r\n0\r\n\$2\r\n-1\r\n"
}

function redis_set_array() {
	typeset REDIS_ARRAY="$1"
	typeset -a REDIS_ARRAY_VAL=("${!2}")
	
	for i in "${REDIS_ARRAY_VAL[@]}"
	do
		printf %b "*3\r\n\$5\r\nRPUSH\r\n\$${#REDIS_ARRAY}\r\n$REDIS_ARRAY\r\n\$${#i}\r\n$i\r\n"
	done
}
