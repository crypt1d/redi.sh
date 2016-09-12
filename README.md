# redi.sh

Redi.sh is a primitive Redis client, written entirely in Bash. It allows you to read/write keys and sets from redis as if they were regular Bash variables.

##Usage:

>By default redi.sh reads input from stdin and interprets it as a variable or array (if -a is used).

```
./redi.sh [-a] [-g <variable|array>] [-p <password>] [-H <hostname>] [-P <port>]

    -a              : Tells the script that we are working with arrays, instead of regular variables.
    -g <name>       : Get the variable/array specified by <name> and output it to stdout.
	-s <name>		: Set the variable/array specified by <name> with the input from stdin.
    -p <password>   : Use "AUTH <password>" before running the SET/GET command to authenticate to redis.
    -H <hostname>   : Specify a custom hostname to connect to. Default is localhost.
    -P <port>       : Specify a custom port to connect to. Default is 6379.
```

##Example:

```shell
$ echo "this is a variable" | ./redi.sh -s testvar
$ ./redi.sh -g testvar
this is a variable
```

```shell
$ echo red green blue | ./redi.sh -as Colors
$ ./redi.sh -ag Colors
red
green
blue
```

License
----

MIT
