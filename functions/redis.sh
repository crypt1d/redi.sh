#!/bin/bash

function redis_read_str() {
        typeset REDIS_STR="$@"
        printf %b "$REDIS_STR" | cut -f2 -d"+" | tr -d '\r'
}

function redis_read_err() {
        typeset REDIS_ERR="$@"
        printf %s "$REDIS_ERR" | cut -f2 -d"-"
        exit 1
}

function redis_read_int() {
        typeset -i OUT_INT=$(printf %s $1 | tr -d '\:' | tr -d '\r')
        printf %b "$OUT_INT"
}

function redis_read_bulk() {
        typeset -i BYTE_COUNT=$1
        if [[ $BYTE_COUNT -lt 0 ]]; then
                echo "ERROR: Null or incorrect string size returned." >&2
                exit 1
        fi

        dd bs=1 count=$BYTE_COUNT status=noxfer <&3 2>/dev/null
}

function redis_read_array() {
        typeset -i PARAM_COUNT=$1
        if [[ $PARAM_COUNT -lt 0 ]]; then
                echo "ERROR: Null or incorrect array size returned." >&2
                exit 1
        fi

        typeset -i CUR_PARAM=1
        while read line
        do
                redis_read
                ((CUR_PARAM+=1))

                if [[ $CUR_PARAM -gt $PARAM_COUNT ]]; then
                        break
                fi

        done<&3

}

function redis_read() {

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
                        redis_read_bulk $bytecount
                        ;;
                "*")
                        #echo "This is an array."
                        paramcount=$(printf %b "$socket_data" | cut -f2 -d"\$" | tr -d '\r')
                        readis_read_array $paramcount
                        ;;
        esac

        break

done<&3

}

function redis_compose_cmd() {
        typeset -i PARAM_NUM=$(printf %b "$@" | wc -w )
        typeset REDIS_CMD

        for i in "$@"
        do
                typeset -i PARAM_NUM=$(printf %b "$i" | wc -w)
                REDIS_CMD="$REDIS_CMD*$PARAM_NUM\r\n"
                for y in $i
                do
                        REDIS_CMD="$REDIS_CMD""\$${#y}\r\n$y\r\n"
                done
        done

       printf %b "$REDIS_CMD"
}
