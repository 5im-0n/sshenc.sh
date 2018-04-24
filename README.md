# sshencdec.sh

bash script to encrypt data using a users ssh public key.

> If you received a message from someone that was encrypted with this script, you can
> decrypt it with your ssh private key using the following command:

```
./sshencdec.sh -s ~/.ssh/id_rsa < file-containing-the-encrypted-text.txt
```

## install
```
wget https://git.e.tern.al/s2/sshencdec/raw/branch/master/sshencdec.sh
chmod +x sshencdec.sh
```

## examples

### encrypt a file using your own ssh public key
```
./sshencdec.sh -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt
```

### encrypt a file using multiple recipients (broadcast encryption)
```
./sshencdec.sh -p ~/.ssh/id_rsa.pub -p id_rsa-alice.pub -p id_rsa-bob.pub < plain-text-file.txt > encrypted.txt
```

### encrypt a file using the public key of a github user
```
./sshencdec.sh -p <(curl -sf "https://github.com/S2-.keys" | tail -n1) < plain-text-file.txt
```

this line fetches the first public key for the github user `S2-` and encrypts the file `plain-text-file.txt` using this key.

### decrypt a file
```
./sshencdec.sh -s ~/.ssh/id_rsa < encrypted.txt
```
