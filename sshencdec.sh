#!/bin/bash

# A POSIX variable
OPTIND=1 # reset in case getopts has been used previously in the shell.

public_key= #"~/.ssh/id_rsa.pub"
private_key= #"~/.ssh/id_rsa"

me=`basename "$0"`

show_help() {
cat << EOF
usage: $me [-p <public ssh key> | -s <private ssh key>] [-h]

examples:
    - encrypt a file
        $me -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt

    - decrypt a file
        $me -s ~/.ssh/id_rsa < encrypted.txt

$me home page: https://git.e.tern.al/s2/sshencdec
EOF
}

while getopts "h?p:s:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    p)  public_key=$OPTARG
        ;;
    s)  private_key=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

temp_file="$(mktemp "${TMPDIR:-/tmp}/$(basename "$0").XXXXXX")"
trap '{ rm -f "$temp_file"; }' EXIT

if [[ -e "$public_key" ]]; then
    if openssl rsautl -encrypt -pubin -inkey <(ssh-keygen -f "$public_key" -e -m PKCS8) -ssl > "$temp_file"; then
        echo "-- encrypted with https://git.e.tern.al/s2/sshencdec"
        openssl base64 < "$temp_file"
    fi
elif [[ -e "$private_key" ]]; then
    openssl base64 -d | openssl rsautl -decrypt -inkey $private_key
else
    show_help
    exit 1
fi
