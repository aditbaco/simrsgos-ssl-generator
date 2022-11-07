# SIMRSGOS SSL Certificate Generator
## Overview
This script can auto-generate a local trusted certificate for SIMRSGOS V2+ Apache based HTTPS server

## Requirements
* Root priviledges
* `openssl` library to generate certificates and keys
* A local HTTPS-enabled web server to test your certificate

## Certificate Instalation

### Pre-requisites
* Put this script in the directory of your choice, the simplest one is in your root directory ```/root/```
* Give script executable access to this script using command ```chmod +x sslcert.sh```

### Usage
* Step 1 - Edit required config variables, open this script using nano and change field data value at the top of this script
* Step 2 - Install required packages and set config file using ```bash sslcert.sh config```
* Step 3 - Generate certificate using ```bash sslcert.sh install```
* Enjoy!

## References
https://docs.simrsgosv2.simpel.web.id/docs/konfigurasi/keamanan/
