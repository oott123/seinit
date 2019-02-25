# seinit

only for yum or apt based system

use at your own risk

MIT license

## Usage

```bash
bash -c "$( curl https://raw.githubusercontent.com/oott123/seinit/master/seinit.sh)"
```

Shell

```bash
wget -O /tmp/seinit.sh https://raw.githubusercontent.com/oott123/seinit/master/seinit.sh
SEI_SHELL=1 bash --init-file /tmp/seinit.sh
```

## update (replace) keys

```bash
wget -O /usr/local/bin/se-update-keys https://raw.githubusercontent.com/oott123/seinit/master/update-keys.sh && chmod +x /usr/local/bin/se-update-keys&& /usr/local/bin/se-update-keys
crontab -l | grep -v /usr/local/bin/se-update-keys | { cat; echo "3 5 * * * /usr/local/bin/se-update-keys" } | crontab -
```
