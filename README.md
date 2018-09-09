# Introduction

**A**(rch)**L**(inux)**I**(nstall)**S**(cript) is a very minimal script that makes my installations of Arch Linux on my various machines as painless and fast as possible. It goes from blank to ready to go in a matter of minutes. Bonus point, everything is automated. 

This script currently supports installs on:
- EUFI systems
- Non-EUFI systems
- External storage

**NOTE:** This script only supports basic hardware with Intel inside. If you need to, you'll have to install additional drivers yourself once the installation is completed.

# How to use ? 

### Step 1: Connect to the internet

Wireless method:

```bash
wifi-menu
```

**OR**

Wired method:

```bash
systemctl restart dhcpcd && sleep 5
```

### Step 2: Download and launch the installer

Recommended method:

```bash
wget https://github.com/gawlk/alis/blob/master/fifo.sh
chmod +x fifo.sh
# Review the code and check that everything is up to date according to the "Installation guide"
./fifo.sh
```

**OR**

Fastest method:

```bash
curl -sSL https://git.io/fAlOi | bash
```
