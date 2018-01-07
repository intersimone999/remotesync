# remotesync
[![Gem Version](https://badge.fury.io/rb/remotesync.svg)](https://badge.fury.io/rb/remotesync)

This makes very easy to keep remote/local folders synched. It works through three basic commands: `rrinit`, to initialize a folder;
`rrpull`, to update the local folder from the remote one; `rrpush`, to update the remote folder from the local one.
remotesync requires ssh and uses the `scp` command to work.

# Initialization
`rrinit` needs two mandatory parameters: remote host address and remote path.
```sh
rrinit 192.168.1.20 /path/to/remote/folder
```

Also, rrinit allows to specify extra options, like the name of the remote user, the remote ssh port, the network namespace to use
and the owner of the local folder (which defaults to the current user). It is possible to specify the type of operations allowed
(i.e., push-only or pull-only), to prevent unintentional overwrites.

# Pull
`rrpull` copies the remote folder to the local one (current working directory). It is possible to pull specific files/folders specifying them with the `-d` or `-f` options.

# Push
`rrpush` copies the local folder to the remote one (current working directory). It is possible to push specific files/folders specifying them with the `-d` or `-f` options.

# Example
```sh
/home/user/test$ rrinit 192.168.1.20 /path/to/remote/folder/test
/home/user/test$ rrpull #Pull the entire remote folder
/home/user/test$ echo "test" > file1.txt
/home/user/test$ cd test2
/home/user/test/test2$ echo "test" > file2.txt
/home/user/test/test2$ rrpush #Push the "test2" folder only, i.e. "file1.txt" is not pushed
```
