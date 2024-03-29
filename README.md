# Deterministic Builds with [Gitian](https://gitian.org)

## Overview

### What is this?

[Gitian](https://gitian.org) provides a framework for generating reproducible build results of a software package.

The problem this solves is that in open source software (OSS) security and trust lies in the fact that the
software sources are public, and everyone can (at least in theory) verify that the software does what it claims to do,
and nothing else, in particular that it doesn't contain malware. While this trust mechanism works fine for source
code, it does not for binaries.

Ready-made binaries are a requirement for many users who lack the skills or the resources to build their own binaries
from the trusted source code. So how can anyone verify that a binary program is in fact the result from compiling a
given source code? Enter Gitian.

The idea is that in a well-defined environment (operating system, compiler, libraries and other tools) the result of
a build can be made to be byte-wise identical for everybody. There are some pitfalls, e. g. some build steps might
depend on timestamps etc., but generally it is possible. Once the build result can be reproduced reliably it becomes
possible to let many people perform the build independently and digitally sign the result. These signatures in turn
can be verified by less technically inclined users, who are then able to trust the binaries if they are willing to
trust those that signed them. Here, "trust" means that **all** signers would have to cooperate in order to sneak
through a piece of malware as the "trusted" binary!

### Structure

This repository contains the following components:

* `descriptors` - contains `.yml`-files describing each build type, where "build type" refers to a combination of software package, operating system and architecture
* `signatures` - contains individual user's build "manifest" and GPG signature
* `signers` - contains some public keys of regular signers for convenience.  **Do not trust a key just because it is listed here!**
* `supplement` - contains additional files to be included in binary distributions
* `vendor/gitian-builder` - submodule of the original gitian framework, as used in this project

## Preparation

First of all, you need some form of virtualization support on your system. Currently supported by gitian are Docker, KVM, LXC and VirtualBox.

Your user must be able to run and access such virtualized environments. Depending on your base system it may be sufficient to add your user to a certain group. As a fallback you may be able to use `sudo`.

You must have GnuPG installed and on your path as `gpg`.

Instructions on how to install required software on some OSes and prepare a gitian base environment can be found [here](https://github.com/devrandom/gitian-builder/blob/master/README.md).
You should follow the described steps until you have completed the "Sanity-testing" section successfully. Be sure to use the "bionic" suite for your base image.

If you want to build build executables for Mac you'll need to download MacOSX SDK 10.15.
It is contained in the Xcode 11.1 distribution, which is available at https://developer.apple.com/xcode/resources/ under "Command Line Tools & Older Versions of Xcode". .
After downloading Xcode, you can extract the SDK as described [here](https://github.com/tpoechtrager/osxcross#packaging-the-sdk).
The resulting file `MacOSX10.15.sdk.tar.xz` must be put in the `vendor/gitian-builder/inputs` subdirectory.

### Example for Docker

`dockerd` must be running and the current user must have sufficient privileges to use it.

#### Check out bitshares-gitian

```
git clone https://github.com/bitshares/bitshares-gitian.git
cd bitshares-gitian
git submodule update --init --recursive
```

#### Create base VMs

Note:
* Since BitShares-Core test-7.0.0, we build all binaries on Ubuntu 20.04 LTS (Focal).
* Before BitShares-Core test-7.0.0 and since BitShares-Core 6.0.0, we build Linux and macOS binaries on Ubuntu 18.04 LTS (Bionic), and for Windows builds we use Ubuntu 20.04 LTS (Focal).
* The test-6.0.0, test-6.0.1 and test-6.0.2 Linux binaries were built with Ubuntu 16.04 LTS (Xenial), macOS binaries were built with Ubuntu 18.04 LTS (Bionic), Windows binaries were built with Ubuntu 20.04 LTS (Focal).
* For earlier versions of BitShares-Core, for better binary compatibility we build Linux binaries on Ubuntu 16.04 LTS (Xenial), for Mac and Windows builds we use the newer Ubuntu 18.04 LTS (Bionic).

```
vendor/gitian-builder/bin/make-base-vm --docker --suite focal
vendor/gitian-builder/bin/make-base-vm --docker --suite bionic
vendor/gitian-builder/bin/make-base-vm --docker --suite xenial
```

#### Sanity-testing

```
export USE_DOCKER=1
export PATH=$PATH:$(pwd)/vendor/gitian-builder/libexec
make-clean-vm --suite bionic
start-target 64 bionic-amd64
on-target ls -la
# total 12
# drwxr-xr-x 2 ubuntu ubuntu   57 May 30 08:36 .
# drwxr-xr-x 1 root   root     20 May 30 08:36 ..
# -rw-r--r-- 1 ubuntu ubuntu  220 Apr  4  2018 .bash_logout
# -rw-r--r-- 1 ubuntu ubuntu 3771 Apr  4  2018 .bashrc
# -rw-r--r-- 1 ubuntu ubuntu  807 Apr  4  2018 .profile
stop-target
```

## Usage

Gitian has three modes of operation, *build*, *sign* and *verify*.

Typically, you will either want to *build* and *sign* yourself - or your want to *verify* the signatures that are already present.

All three modes can be invoked by using the `run-gitian` wrapper script in the project's top-level directory.

Enter `./run-gitian --help` to see the available options.

**Note:** be sure to specify the underlying virtualization mechanism with gitian's environment variables, unless you use KVM!
(`USE_DOCKER=1` for Docker, `USE_LXC=1` for LXC or `USE_VBOX=1` for VirtualBox.)

### Build only

Examples:

* build Linux binaries for BitShares-Core 5.2.1:

  `./run-gitian -b -O linux 5.2.1`

* build macOS binaries for BitShares-Core test-6.0.0:

  `./run-gitian -b -O osx test-6.0.0`

* build Windows binaries for BitShares-Core 5.2.1:

  `./run-gitian -b -O win 5.2.1`

### Build and sign

Example: build version 3.1.0 using 3 cores and 8 gigabytes of RAM, then sign with key ID 2d2746cc:

`./run-gitian -b -s 2d2746cc 3.1.0 -m 8192 -j 3`

This will create a subdirectory under `signatures`. If you want to contribute, please commit your signature and create a pull request. Make sure your public key is publicly available on GPG key servers.

### Verify

Example: verify version 3.1.0:

`./run-gitian -v 3.1.0`

### Use binary

A `bz2` file(`bitshares-3.1.0-linux-amd64-bin.tar.bz2`) will be generated at `bitshares-gitian/vendor/gitian-builder/build/out/`  after any `./run-gitan -b` is executed.

Example: use built witness_node binary: 

```
cd vendor/gitian-builder/build/out/
tar xvfj bitshares-3.1.0-linux-amd64-bin.tar.bz2
./bitshares-core-3.1.0-linux-amd64-bin/witness_node
```

## Repository branches

From time to time it may become necessary to update the build descriptors, e. g. to update dependencies, or for other improvements.
Such changes are likely to lead to different build results, which would invalidate existing signatures.
Also, if a new version of bitshares-core makes such changes necessary, the change might break the build for older versions.

For ease of maintenance, we create a new branch for each new version or pre-release of BitShares-Core, and add signatures (if any) in that branch.
Some branches may be identical and redundant.
The master branch is kept clean for development.

### Existing branches

Note: The source code of the `zlib-1.3` library has been removed from the official website (https://zlib.net). As a result, Windows binaries and macOS binaries of BitShares-Core built with the following branches can no longer be rebuilt or verified as-is.
* [7.0.2](https://github.com/bitshares/bitshares-gitian/tree/7.0.2)
* [test-7.0.4](https://github.com/bitshares/bitshares-gitian/tree/test-7.0.4)
* [7.0.1](https://github.com/bitshares/bitshares-gitian/tree/7.0.1)
* [test-7.0.3](https://github.com/bitshares/bitshares-gitian/tree/test-7.0.3)
* [7.0.0](https://github.com/bitshares/bitshares-gitian/tree/7.0.0)
* [test-7.0.2](https://github.com/bitshares/bitshares-gitian/tree/test-7.0.2)

Note: The source code of the `zlib-1.2.13` library has been removed from the official website (https://zlib.net). As a result, Windows binaries and macOS binaries of BitShares-Core built with the following branches can no longer be rebuilt or verified as-is.
* [test-7.0.1](https://github.com/bitshares/bitshares-gitian/tree/test-7.0.1)
* [test-7.0.0](https://github.com/bitshares/bitshares-gitian/tree/test-7.0.0)
* [6.1.0](https://github.com/bitshares/bitshares-gitian/tree/6.1.0)
* [test-6.1.2](https://github.com/bitshares/bitshares-gitian/tree/test-6.1.2)
* [test-6.1.1](https://github.com/bitshares/bitshares-gitian/tree/test-6.1.1)
* [test-6.1.0](https://github.com/bitshares/bitshares-gitian/tree/test-6.1.0)

Note: Due to security issues, the source code of the `zlib-1.2.12` library has been removed from the official website (https://zlib.net). As a result, Windows binaries and macOS binaries of BitShares-Core built with the following branches can no longer be rebuilt or verified as-is.
* [test-6.0.4](https://github.com/bitshares/bitshares-gitian/tree/test-6.0.4)
* [6.0.2](https://github.com/bitshares/bitshares-gitian/tree/6.0.2)

Note: Due to security issues, the source code of the `zlib-1.2.11` library has been removed from the official website (https://zlib.net). As a result, Windows binaries and macOS binaries of BitShares-Core built with the following branches can no longer be rebuilt or verified as-is.
* [6.0.1](https://github.com/bitshares/bitshares-gitian/tree/6.0.1)
* [test-6.0.3](https://github.com/bitshares/bitshares-gitian/tree/test-6.0.3)
* [6.0.0](https://github.com/bitshares/bitshares-gitian/tree/6.0.0)
* [test-6.0.2](https://github.com/bitshares/bitshares-gitian/tree/test-6.0.2)
* [test-6.0.1](https://github.com/bitshares/bitshares-gitian/tree/test-6.0.1)
* [test-6.0.0](https://github.com/bitshares/bitshares-gitian/tree/test-6.0.0)
* [5.2.1](https://github.com/bitshares/bitshares-gitian/tree/5.2.1)
* [test-5.2.1](https://github.com/bitshares/bitshares-gitian/tree/test-5.2.1)
* [5.2.0](https://github.com/bitshares/bitshares-gitian/tree/5.2.0)
* [test-5.2.0](https://github.com/bitshares/bitshares-gitian/tree/test-5.2.0)
* [5.1.0](https://github.com/bitshares/bitshares-gitian/tree/5.1.0)
* [5.0.0](https://github.com/bitshares/bitshares-gitian/tree/5.0.0)
* [4.0.0](https://github.com/bitshares/bitshares-gitian/tree/4.0.0)

Note: it is a bit tricky to reproduce the `3.3.1` and `3.3.2` binaries due to changes on minor version of operating systems. Please check [issue #34](https://github.com/bitshares/bitshares-gitian/issues/34) for more info.
* [3.3.2](https://github.com/bitshares/bitshares-gitian/tree/3.3.2)
* [3.3.1](https://github.com/bitshares/bitshares-gitian/tree/3.3.1)


## Further Reading

See https://reproducible-builds.org/docs/ for a deeper insight into the challenges faced by this task, and for possible explanations why you cannot reproduce a given build.
