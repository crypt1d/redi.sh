#!/bin/bash -e

typeset -a Colors=([0]='red' [1]='green' [2]='blue')
typeset | grep ^Colors= | ./redi.sh -a

out="$(./redi.sh -ag Colors)"

[[ 'Colors=([0]="red" [1]="green" [2]="blue")' == "$out" ]]
