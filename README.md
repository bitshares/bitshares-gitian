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

If you want to build build executables for Mac you'll need to download MacOSX SDK 10.14.
It is contained in the Xcode 10.3 distribution, which is available at https://developer.apple.com/xcode/resources/ under "Command Line Tools & Older Versions of Xcode". .
After downloading Xcode, you can extract the SDK as described [here](https://github.com/tpoechtrager/osxcross#packaging-the-sdk).
The resulting file `MacOSX10.14.sdk.tar.xz` must be put in the `vendor/gitian-builder/inputs` subdirectory.

### Example for Docker

`dockerd` must be running and the current user must have sufficient privileges to use it.

#### Check out bitshares-gitian

```
git clone https://github.com/bitshares/bitshares-gitian.git
cd bitshares-gitian
git submodule update --init --recursive
```

#### Create base VM

```
vendor/gitian-builder/bin/make-base-vm --docker --suite bionic
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

The plan for such breaking changes is:

* create a branch from master, named after the latest supported core version, immediately before the breaking commit
* future signatures for these supported versions can be added on that branch only
* immediately after the breaking commit, remove all signatures for no-longer supported versions from master

## Further Reading

See https://reproducible-builds.org/docs/ for a deeper insight into the challenges faced by this task, and for possible explanations why you cannot reproduce a given build.
