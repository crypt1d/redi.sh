#!/bin/bash -e

typeset Color='red'
typeset | grep ^Color= | ./redi.sh

out="$(./redi.sh -g Color)"

[[ 'red' == "$out" ]]
