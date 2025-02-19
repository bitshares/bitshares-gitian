This package contains precompiled binaries of the BitShares core software.

See https://docs.bitshares.dev/ for documentation.

Source code can be found at https://github.com/bitshares/bitshares-core .

See the file LICENSE.txt in this package for the terms of use.

**Note to Linux users:** depending on your distribution, cli_wallet may receive the error "TLS handshake failed" when connecting to an ssl-protected wss:// URL.
As a workaround, you can set the environment variable SSL_CERT_DIR or SSL_CERT_FILE, e. g. like this (the actual file name or directory name may vary):
```
export SSL_CERT_DIR="$( openssl version -d | cut -d\" -f 2 )/certs"
export SSL_CERT_FILE="$( openssl version -d | cut -d\" -f 2 )/cert.pem"
```

**Note to Mac users:** in order to make SSL certificate verification work it may be necessary to either install the homebrew openssl package, or to [export CA certificates from the KeyChain tool](http://movingpackets.net/2015/03/18/telling-openssl-about-your-root-certificates/).
It may also be necessary to point the environment variables SSL_CERT_DIR or SSL_CERT_FILE to the correct location, see above.
