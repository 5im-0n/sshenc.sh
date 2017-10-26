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

cleanup() {
    rm -f "$temp_file"
    rm -f "$temp_file_key"
    rm -f "$temp_file_key.enc"
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

temp_file="$(mktemp "${TMPDIR:-/tmp}/$(basename "$0").XXXXXX.enc")"
temp_file_key="$(mktemp "${TMPDIR:-/tmp}/$(basename "$0").XXXXXX.key")"
trap cleanup EXIT

#encrypt
if [[ -e "$public_key" ]]; then
    openssl rand 32 > $temp_file_key

    if openssl rsautl -encrypt -pubin -inkey <(ssh-keygen -f "$public_key" -e -m PKCS8) -in "$temp_file_key" -out "$temp_file_key.enc"; then
        if openssl enc -aes-256-cbc -salt -pass file:"$temp_file_key" > "$temp_file"; then
            echo "-- encrypted with https://git.e.tern.al/s2/sshencdec"
            echo "-- key"
            echo "$(openssl base64 -in "$temp_file_key.enc")"
            echo "-- /key"
            openssl base64 < "$temp_file"
        fi
    fi

#decrypt
elif [[ -e "$private_key" ]]; then
    stdin=`cat`
    key_enc=$(echo "$stdin" | awk '/-- key/{f=1;next} /-- \/key/{f=0} f')
    cypher=$(echo "$stdin" | sed -e '1,/-- \/key/d')
    echo "$key_enc" | openssl base64 -d | openssl rsautl -decrypt -ssl -inkey "$private_key" > "$temp_file"
    echo "$cypher" | openssl base64 -d | openssl aes-256-cbc -d -pass file:"$temp_file"

else
    show_help
    exit 1
fi
