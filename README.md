# sshenc.sh
> bash script to encrypt data using a users ssh public key.

If you received a message from someone that was encrypted with this script, you can decrypt it with your ssh private key using the following command without installing anything:
```
bash <(curl -s https://sshenc.sh/sshenc.sh) -s ~/.ssh/id_rsa < file-containing-the-encrypted-text.txt
```
sshenc.sh uses openssl under the hood, so you need to have that installed in your path to make it work.

## Install
```
wget https://sshenc.sh/sshenc.sh
chmod +x sshenc.sh
```

## Examples

### encrypt a file using your own ssh public key
```
sshenc.sh -p ~/.ssh/id_rsa.pub < plain-text-file.txt > encrypted.txt
```

### encrypt a file using multiple recipients (broadcast encryption)
```
sshenc.sh -p ~/.ssh/id_rsa.pub -p id_rsa-alice.pub -p id_rsa-bob.pub < plain-text-file.txt > encrypted.txt
```

### encrypt a file using the public key of a github user
```
sshenc.sh -p <(curl -sf "https://github.com/S2-.keys" | grep ssh-rsa | tail -n1) < plain-text-file.txt
```
this line fetches the first public key for the github user S2- and encrypts the file plain-text-file.txt using this key.

### dedecrypt a file
```
sshenc.sh -s ~/.ssh/id_rsa < encrypted.txt
```

## License
[MIT](https://opensource.org/licenses/MIT)
