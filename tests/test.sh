cleanup() {
    rm -rf "$tempfile"
}

trap cleanup EXIT


tempfile=$(tempfile)
plaintext=$(cat sometext)

echo -n 'testing multiple pubkeys: '
../sshenc.sh -p id_rsa-1.pub -p id_rsa-2.pub -p id_rsa-3.pub < sometext > $tempfile

for i in {1..3}; do
    cyph=$(../sshenc.sh -s id_rsa-$i < $tempfile)
    if [ "$cyph" == "$plaintext" ]; then
        echo -n "key$i: ✓ "
    else
        echo -n "key$i: ⛝ "
    fi
done

echo
echo done.
