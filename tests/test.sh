cleanup() {
    rm -rf "$tempfile"
}

trap cleanup EXIT


tempfile=$(tempfile)
plaintext=$(cat sometext)

echo -n 'testing multiple pubkeys: '
../sshenc.sh -p id_rsa-1.pub -p id_rsa-2.pub -p id_rsa-3.pub < sometext > $tempfile
cyph=$(../sshenc.sh -s id_rsa-1 < $tempfile)
if [ "$cyph" == "$plaintext" ]; then
    echo -n "key1: ✓ "
else
    echo -n "key1: ⛝ "
fi
cyph=$(../sshenc.sh -s id_rsa-2 < $tempfile)
if [ "$cyph" == "$plaintext" ]; then
    echo -n "key2: ✓ "
else
    echo -n "key2: ⛝ "
fi
cyph=$(../sshenc.sh -s id_rsa-3 < $tempfile)
if [ "$cyph" == "$plaintext" ]; then
    echo -n "key3: ✓ "
else
    echo -n "key4: ⛝ "
fi

echo
echo done.
