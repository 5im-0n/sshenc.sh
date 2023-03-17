# ![sshenc.sh](logo.png)

**bash script to encrypt data using a users ssh public key**

If you received a message from someone that was encrypted with this script, you can decrypt it with your ssh private key using the following command without installing anything:
```
bash <(curl -s https://raw.githubusercontent.com/5im-0n/sshenc.sh/master/sshenc.sh) -s ~/.ssh/id_rsa < file-containing-the-encrypted-text.txt
```
sshenc.sh uses openssl under the hood, so you need to have that installed in your path to make it work.

## Install
```
curl -O https://raw.githubusercontent.com/5im-0n/sshenc.sh/master/sshenc.sh
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
sshenc.sh -g S2- < plain-text-file.txt
```
this line fetches the public keys for the github user S2- and encrypts the file plain-text-file.txt using its key(s).

### decrypt a file
```
sshenc.sh -s ~/.ssh/id_rsa < encrypted.txt
```

## Notes
[OpenSSL 1.1.1](https://www.openssl.org/docs/man1.1.1/man1/openssl-enc.html) introduced a not backwards compatible change: the default digest to create a key from the passphrase changed from md5 to sha-256.  
Also, a new `-iter` parameter to explicitly specify a given number of iterations on the password in deriving the encryption key was added.  
Before OpenSSL 1.1.1 this option was not available.  
Since the new parameters are more secure, `sshenc.sh` changed to adopt them, so since 2019-11-26, files encrypted with a previous version of `sshenc.sh` will not decrypt.  
To do so, use the prevous `sshenc.sh` script, located at [https://raw.githubusercontent.com/5im-0n/sshenc.sh/master/sshenc-pre1.1.1.sh](https://raw.githubusercontent.com/5im-0n/sshenc.sh/master/sshenc-pre1.1.1.sh).

## License
[MIT](https://opensource.org/licenses/MIT)
