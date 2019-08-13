# Introduction

**M**(inimal)**A**(rch)**L**(inux)**I**(nstaller) is a very simple script that makes my installations of Arch Linux on my various machines as painless and fast as possible. It goes from blank to ready to go in a matter of minutes.

Supports:
- EUFI systems
- Non-EUFI systems
- installation on external storages

**NOTE:** Only Intel hardware is supported out of the box. If you need to, you'll have to install additional drivers yourself once the installation is completed.

# How to use ? 

### Step 1: Connect to the internet

Wireless:

```bash
wifi-menu
```

**OR**

Wired:

```bash
systemctl restart dhcpcd
```

### Step 2: Download and launch the installer

Recommended:

```bash
wget https://gitlab.com/gawlk/mali/raw/master/mali
less mali # Review the code and check that everything is up to date according to the "Installation guide" on the Arch Linux wiki
bash mali
```

**OR**

Not recommended:

```bash
curl -sSL tiny.cc/mali | bash
```
