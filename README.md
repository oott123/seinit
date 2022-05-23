# seinit

only for yum or apt based system

use at your own risk

MIT license

## Usage

### From GitHub

```bash
wget https://raw.githubusercontent.com/oott123/seinit/master/seinit.sh -O seinit.sh && chmod +x seinit.sh && ./seinit.sh
```

### From jsdelivr

```bash
wget https://cdn.jsdelivr.net/gh/oott123/seinit@master/seinit.sh -O seinit.sh && chmod +x seinit.sh && LOC=CN ./seinit.sh
```

### From gitlab pages

```bash
wget https://oott123.urn.cx/seinit/seinit.sh -O seinit.sh && chmod +x seinit.sh && ./seinit.sh
```

(CN)

```
wget https://oott123.urn.cx/seinit/seinit.sh -O seinit.sh && chmod +x seinit.sh && LOC=CN ./seinit.sh
```

Shell

```bash
wget -O /tmp/seinit.sh https://oott123.urn.cx/seinit/seinit.sh
SEI_SHELL=1 bash --init-file /tmp/seinit.sh
```

## update (replace) keys

```bash
wget -O /usr/local/bin/se-update-keys https://oott123.urn.cx/seinit/update-keys.sh && chmod +x /usr/local/bin/se-update-keys && /usr/local/bin/se-update-keys; crontab -l | grep -v /usr/local/bin/se-update-keys | { cat; echo "3 5 * * * /usr/local/bin/se-update-keys"; } | crontab -
```
