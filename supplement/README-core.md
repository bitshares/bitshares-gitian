This package contains precompiled binaries of the BitShares core software.

See https://how.bitshares.works/ for documentation.

Source code can be found at https://github.com/bitshares/bitshares-core .

See the file LICENSE.txt in this package for the terms of use.

**Note:** depending on your Linux distribution, cli_wallet may receive the error "TLS handshake failed" when connecting to an ssl-protected wss:// URL.
As a workaround, you can set the environment variable SSL_CERT_DIR or SSL_CERT_FILE, e. g. like this (the actual file name or directory name may vary):
```
export SSL_CERT_DIR="$( openssl version -d | cut -d\" -f 2 )/certs"
export SSL_CERT_FILE="$( openssl version -d | cut -d\" -f 2 )/cert.pem"
```
