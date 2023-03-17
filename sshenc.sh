#!/usr/bin/env bash

# --- constants
me=sshenc.sh

show_help() {
cat << EOF
usage: $me [[-p <public ssh key> | -g <github handle>]| -s <private ssh key>] [-h]

examples:

    - decrypt a file
    $me -s ~/.ssh/id_rsa < encrypted.txt

    - encrypt a file
    $me -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt

    - encrypt using a GitHub users public SSH key (requires curl and bash 3.2)
    $me -g foo < plain-text-file.txt > encrypted.txt

    - encrypt using multiple public keys (file can be read by any associated private key)
    $me -g foo -g bar -p baz -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt

$me home page: https://github.com/5im-0n/sshenc.sh/
EOF
}

# --- process option parameters
OPTIND=1                           # reset in case getopts has been used previously in the shell
while getopts "h?p:s:g:" opt; do
    case "$opt" in
    h|\?)
    show_help
    exit 0
    ;;
    p)  public_key+=("$OPTARG")
    ;;
    s)  private_key=$OPTARG
    ;;
    g)  github_handle+=("$OPTARG")
    esac
done

shift $((OPTIND -1))               # pop the processed options off the stack
[ "$1" = "--" ] && shift

# --- setup environment

# data cache files
temp_dir="$(mktemp -d -t "$me.XXXXXX")"
temp_file_key="$(mktemp "$temp_dir/$me.XXXXXX.key")"
temp_file="$(mktemp "$temp_dir/$me.XXXXXX.cypher")"

cleanup() {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

# os specific configuration
case "$(uname -s 2>/dev/null)" in
    Darwin)
        if [[ -n $(openssl version | grep -Eo "LibreSSL [2-9]") ]]; then
            openssl_params=''
        else
            echo >&2 "Install openssl 1.1.1 or higher and add it to your \$PATH"
            echo ''
            echo '    brew install openssl'
            echo '    echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' >> ~/.bash_profile'
            echo '    source ~/.bash_profile'
            echo ''
            exit 1
        fi
    ;;
    *)
        openssl_params='-pbkdf2 -iter 100000'
esac

# --- retrieve ssh keys from github
if [[ "${#github_handle[@]}" -gt 0 ]]; then
    if ! which curl >/dev/null ; then
        >&2 echo "curl command not found"
        exit 1
    fi

    OLDMASK=$(umask); umask 0266
    for handle in "${github_handle[@]}"
    do
        curl -s "https://github.com/$handle.keys" | grep ssh-rsa > "$temp_dir/$handle"
        if [ -s "$temp_dir/$handle" ]; then
            key_index=0
            while IFS= read -r key; do
                printf "%s" "${key}" > "$temp_dir/$handle.$key_index"
                public_key+=("$temp_dir/$handle.$key_index")
                key_index=$((key_index+1))
            done < "$temp_dir/$handle"
        fi
    done
    umask "$OLDMASK"
fi

# --- encrypt stdin
if [[ "${#public_key[@]}" > 0 ]]; then
    openssl rand 32 > $temp_file_key

    echo "-- encrypted with https://github.com/5im-0n/sshenc.sh/"
    echo "-- keys"
    for pubkey in "${public_key[@]}"
    do
        if [[ -e "$pubkey" ]]; then
            convertedpubkey=$temp_dir/$(basename "$pubkey").pem
            ssh-keygen -f "$pubkey" -e -m PKCS8 > $convertedpubkey
            #encrypt key with public keys
            if openssl rsautl -encrypt -oaep -pubin -inkey "$convertedpubkey" -in "$temp_file_key" -out $temp_dir/$(basename "$pubkey").key.enc; then
                echo "-- key"
                openssl base64 -in $temp_dir/$(basename "$pubkey").key.enc
                echo "-- /key"
            fi
        fi
    done
    echo "-- /keys"

    if cat | openssl enc -aes-256-cbc -salt $openssl_params -pass file:"$temp_file_key" > "$temp_file"; then
        openssl base64 -A < "$temp_file"
    fi

# --- decrypt stdin
elif [[ -e "$private_key" ]]; then
    stdin=`cat`
    keys_enc=$(echo "$stdin" | awk '/-- keys/{f=1;next} /-- \/keys/{f=0} f')
    cypher=$(echo "$stdin" | sed -e '1,/-- \/keys/d')
    install -m 0600 "$private_key" "$temp_dir/private_key"
    ssh-keygen -p -m PEM -N '' -f "$temp_dir/private_key" >/dev/null

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
    for key in "${keys[@]}"; do
        if $(echo "$key" | openssl base64 -d -A | openssl rsautl -decrypt -oaep -inkey "$temp_dir/private_key" >"$temp_file_key" 2>/dev/null); then
            if echo "$cypher" | openssl base64 -d -A | openssl aes-256-cbc -d $openssl_params -pass file:"$temp_file_key"; then
                decrypted=true
            fi
        fi
    done

    if [ $decrypted = false ]; then
        >&2 echo "no valid decryption key supplied"
        exit 1
    fi

# --- help
else
    show_help
    exit 1
fi
