#!/bin/bash
[ -d ~/.ssh ] || mkdir ~/.ssh
chmod 755 ~/.ssh
[ -f ~/.ssh/authorized_keys ] && cp -r ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLu2oMKdYw4zFvHvG4cQasFWGF9epC8mzqrsHIg7QaerrwIUjui0alLeFQy6QiwUyKzFz3U5kT0fMfKrC9bBCKfnbT+xahSOMyEBqxOVi87Lzj5fVkTCnPpgMuS1YTnKaTHhBwjg1bi/kwXvr10zqeNtzQF+v0nVTVSAav4rQWeNJmXkW26+gsG85SPT7MKQr/+K3RClsa3qBJSTyif1Ha6M+kgUo+rojjw9adPwF7AjSyRd9Ns6IjQhskC5YvzANLLGlLLKka7qkXnlc2eaN+6hu0NDCpsoigoBfND4/owqZLDzH84SSB0eliqPHvOSnX+siUQPs0eFfIp7izH+gFC4rHGexutZSieXKQQwV68utZXYiPcBcH/PLsfQPoLv16mEVpzmxd0JwH43f0HRew/DkS+agL4YNQBOECtxa4pcbz1/EUwfIpZwmMz9eppFrLFFjXNMvYdSKsOlAGbIux5It7hDvmpdplGIva3iwXb28wGzjpkTMBomC+oHT5zIF9ptZyS5EuW68peUGmUWTAsNnsDeB56Rvz7xDfMWCrOc5d0smBepfjy+dBpichhvlhDFqYcamwEW6VNYGP/9awsnkvlb5nIhxQsxsoL8pg5b3+BmUxBLgxj/hTDezU9hArUDqxxaUR9hSnC+BS+lHjvp5tiF3nel8ww9FC17KSww== oott123@device0\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+NF5g0Q/0nlkrawFGbGq4E2EBg/KWN9wzPlTVPZXhcxFeeMzrSSP6y2WuwvmcQzJfnN2WsnvbJsQpkj1/R1zz+Bg6GaS1Z+1USCL6/KU0Jf2fBDMJKENAxX5TUT1WfYUrGhc0utE8wahCZ9MdbkrS33fxYeUdNic9sadbQFYHm3lvcAuYB/G6EzTUWwH5f65pDNhO4m/zeftGTwqCoatvYpSUJVnzCaSvtsz5EEv6QTI3kAPLAsAYv8MWZiyoHLfXMC8+2fDCIJqrMZKfWgGYheqe4JduZlOkhRcQ4NHovqLlUA9J0iuZ5PKupRo8ocwL85RlaeDe2gTY/CNDiYGR notroot@notroot\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtv8RhG4uX9bWc4sh3gPj8Umrcfk0/AcqWkyWM4pX4vFvF33NjNcIimAMJ/Bl78MhMbee3EW/j0sB1bnbi1wiMhxOX54RE95/0wMnThM0tN2Vu+nY+nXqoVCZoyJY6oVENCXgxxEZwfdN42+9k4vtAMiQJsxKj5BtmsEOWXl86E0+e/19XnGzuRnzqJiC8Ep48QK0Sa8FLGoEg4SxbqkeLVIUuZyYEMeEmUz1JKcUmPBFqBmCwevrmYI9wBVIGyYhPl8ktGYsm7HU8sr/pTtaD6sZH0CUjW4/FWgZ2JVCkMVC/P+v3dq/MsZ3UcsY+LM/psgstZQCTYwK/bC6CTdco+lxAVcbMULTPotslYRxMlvE0KpTAxrzTbbGkKrA1XGOm+o8Jdss9jdQpMs3AhuNFgz4iMRh1iCXdC/pFU+XSW4+WMdEjFkVy+jTJMCuYuMVLue3g2rTm4vOdGbAhNJGgf1URK4Yxr2WEG/0vc6GmV2RaQpHHFoE15cNbgx8tGS0PrPQBVxY1Nos1wrTwY8EC3170UtMKwRkoM4wKWbWug7oY6qArBrrdFFGh4IrV/cnuZMGrwcaL2JazkyWc9bz+7pDeZDGwECtqAok7jz+LgLFgY02d+wKwkUKHq489/aQ1v/SYl1w+4egBWFSrHEPEiI2MlDWIUHFBqolJpGf56w== oott123@phone\n" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys