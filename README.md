# redi.sh

Redi.sh is a primitive Redis client, written entirely in Bash. It allows you to read/write keys and sets from redis as if they were regular Bash variables.

##Usage:

>By default redi.sh reads input from stdin and interprets it as a variable or array (if -a is used).

> ./redi.sh [-a] [-g <variable|array>] [-p <password>] [-H <hostname>] [-P <port>]

    -a              : Tells the script that we are working with arrays, instead of regular variables.
    -g <name>       : Get the variable/array specified by <name> and output it to stdin.
    -p <password>   : Use "AUTH <password>" before running the SET/GET command to authenticate to redis.
    -H <hostname>   : Specify a custom hostname to connect to. Default is localhost.
    -P <port>       : Specify a custom port to connect to. Default is 6379.

##Example:
    $ typeset Color="red" 
    $ typeset | grep ^Color= | ./redi.sh 
    $ ./redi.sh -g Color 
    red
    $
    $ typeset -a Colors=([0]="red" [1]="green" [2]="blue")
    $ typeset | grep ^Colors= | ./redi.sh -a
    $ ./redi.sh -ag Colors
    Colors=([0]="red" [1]="green" [2]="blue")
    
License
----

MIT
