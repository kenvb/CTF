# BusyBox Primer

## Introduction
BusyBox is a lightweight set of Unix utilities combined into a single executable, often used in embedded systems and minimal Linux distributions. It provides replacements for common GNU utilities with a smaller footprint.

## Installation

### 1. Installing BusyBox on Linux
You can install BusyBox using your Linux distribution’s package manager or manually download the latest version.

# Install from package manager

# Debian/Ubuntu
```sh
sudo apt update && sudo apt install busybox
```

# Red Hat/CentOS
```sh
sudo yum install busybox
```
# Download and install manually
```sh
wget https://busybox.net/downloads/binaries/latest/busybox-x86_64
chmod +x busybox-x86_64
sudo mv busybox-x86_64 /usr/local/bin/busybox
```
# Running commands with BusyBox
```sh
busybox ls
busybox tar -cvf archive.tar myfolder/
```
# Creating symlinks so BusyBox replaces common commands
```sh
ln -s /usr/local/bin/busybox /usr/local/bin/ls
ln -s /usr/local/bin/busybox /usr/local/bin/tar
ls  # Now this uses BusyBox’s ls
```

# Checking available commands in BusyBox
```sh
busybox --list
```
# Using BusyBox as a minimal shell
```sh
busybox sh
```

# Running an emergency shell
```sh
init=/bin/busybox sh
```
# Using BusyBox in embedded systems
```sh
make defconfig
make install
```
