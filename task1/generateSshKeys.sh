ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "postgres2@pg101 for backup"

# [postgres2@pg101 ~]$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "postgres2@pg101 for backup"
# Generating public/private ed25519 key pair.
# Your identification has been saved in /var/db/postgres2/.ssh/id_ed25519
# Your public key has been saved in /var/db/postgres2/.ssh/id_ed25519.pub
# The key fingerprint is:
# SHA256:w4jDBCraUfRYM5BXPygKfK03r17X7hDNFzN2g34ss/k postgres2@pg101 for backup
# The key's randomart image is:
# +--[ED25519 256]--+
# |  ..+o+..        |
# | o o.=.o o    .  |
# |o + +.+ . o  .=..|
# |o. * + +   +...=.|
# |. . * + S . o+.o |
# |     o o . o .*  |
# |        o o .o   |
# |       o . o  .  |
# |     .o    .o  E |
# +----[SHA256]-----+
# [postgres2@pg101 ~]$

# [postgres2@pg101 ~]$ ls -l ~/.ssh/
# total 14
# -rw-------  1 postgres2 postgres 201 17 апр.  11:59 authorized_keys
# -rw-------  1 postgres2 postgres 419 17 апр.  13:55 id_ed25519
# -rw-r--r--  1 postgres2 postgres 108 17 апр.  13:55 id_ed25519.pub
# [postgres2@pg101 ~]$ 


# теперь можно заходить без пароля
ssh-copy-id -i ~/.ssh/id_ed25519.pub postgres1@pg104