#!/bin/bash

OPTIND=1 # reset in case getopts has been used previously in the shell.

me=sshenc.sh

show_help() {
cat << EOF
usage: $me [-p <public ssh key> | -s <private ssh key>] [-h]

examples:
    - encrypt a file
    $me -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt

    - decrypt a file
    $me -s ~/.ssh/id_rsa < encrypted.txt

$me home page: https://sshenc.sh/
EOF
}

cleanup() {
    rm -rf "$temp_dir"
}

while getopts "h?p:s:" opt; do
    case "$opt" in
    h|\?)
    show_help
    exit 0
    ;;
    p)  public_key+=("$OPTARG")
    ;;
    s)  private_key=$OPTARG
    ;;
    esac
done

shift $((OPTIND -1))

[ "$1" = "--" ] && shift

temp_dir="$(mktemp -d -t "$me.XXXXXX")"
temp_file_key="$(mktemp "$temp_dir/$me.XXXXXX.key")"
temp_file="$(mktemp "$temp_dir/$me.XXXXXX.cypher")"
trap cleanup EXIT

#encrypt
if [[ "${#public_key[@]}" > 0 ]]; then
    openssl rand 32 > $temp_file_key

    echo "-- encrypted with https://sshenc.sh/"
    echo "-- keys"
    for pubkey in "${public_key[@]}"
    do
        if [[ -e "$pubkey" ]]; then
            convertedpubkey=$temp_dir/$(basename "$pubkey").pem
            ssh-keygen -f "$pubkey" -e -m PKCS8 > $convertedpubkey
            #encrypt key with public keys
            if openssl rsautl -encrypt -pubin -inkey "$convertedpubkey" -in "$temp_file_key" -out $temp_dir/$(basename "$pubkey").key.enc; then
                echo "-- key"
                openssl base64 -in $temp_dir/$(basename "$pubkey").key.enc
                echo "-- /key"
            fi
        fi
    done
    echo "-- /keys"

    if cat | openssl enc -aes-256-cbc -salt -pass file:"$temp_file_key" > "$temp_file"; then
        openssl base64 -A < "$temp_file"
    fi

#decrypt
elif [[ -e "$private_key" ]]; then
    stdin=`cat`
    keys_enc=$(echo "$stdin" | awk '/-- keys/{f=1;next} /-- \/keys/{f=0} f')
    cypher=$(echo "$stdin" | sed -e '1,/-- \/keys/d')

    i=0
    while read line ; do \
        if [ "$line" == "-- key" ]; then
            i=$(($i + 1))
        elif [ "$line" == "-- /key" ]; then
            :
        else
            keys[i]="${keys[$i]}$line"
        fi
    done <<< "$keys_enc"

    decrypted=false
    for key in "${keys[@]}"
    do
        if ((echo "$key" | openssl base64 -d -A | openssl rsautl -decrypt -ssl -inkey "$private_key" > "$temp_file") > /dev/null 2>&1); then
            if echo "$cypher" | openssl base64 -d -A | openssl aes-256-cbc -d -pass file:"$temp_file"; then
                decrypted=true
            fi
        fi
    done

    if [ $decrypted = false ]; then
        >&2 echo "no valid decryption key supplied"
        exit 1
    fi

#help
else
    show_help
    exit 1
fi
