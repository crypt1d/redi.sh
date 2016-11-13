#!/bin/bash -e

# Test redi.sh


echo Test str var

typeset Color='red'
typeset | grep ^Color= | ./redi.sh

out="$(./redi.sh -g Color)"

[[ 'red' == "$out" ]]


echo Test array var

typeset -a Colors=([0]='red' [1]='green' [2]='blue')
typeset | grep ^Colors= | ./redi.sh -a

out="$(./redi.sh -ag Colors)"

[[ 'Colors=([0]="red" [1]="green" [2]="blue")' == "$out" ]]


echo Done
