# ksmbd-check

A 30-second check: is KSMBD — the SMB server built into the Linux kernel — actually running on your NAS or Linux server?

Two remote code execution flaws rated 9.0 out of 10 (ZDI-CAN-33774 and ZDI-CAN-33549, disclosed October 22, 2026) affect KSMBD only. They do not affect normal userspace Samba. Most homelabs run Samba, not KSMBD — this script tells you which one your box runs, and whether port 445 is listening.

## Run it

bash ksmbd-check.sh

No root needed for the read-only checks (the port 445 listing may show less detail without root).

## What it checks

1. Whether the ksmbd kernel module is loaded (lsmod)
2. Whether a ksmbd service is active (systemctl)
3. Whether anything is listening on port 445 (SMB)
4. Whether normal Samba (smbd) is running — for the Samba-vs-KSMBD distinction

## What the result means

- KSMBD not running: the two flaws do not affect you. If you run normal Samba, you are not affected either.
- KSMBD running: you are in scope. Stop the ksmbd service / unload the module if you do not need kernel SMB, or block inbound port 445 at your firewall. SMB should never face the internet.

## Facts, as of October 26, 2026

- No CVE numbers exist yet for either flaw, and no confirmed fix has landed in a stable or distribution kernel. The kernel project assigns CVE numbers only once a stable-tree fix exists.
- ZDI-CAN-33774 needs no authentication and exposes any KSMBD server on port 445.
- ZDI-CAN-33549 needs an RDMA-capable interface, a writable KSMBD share, and SMB Direct negotiation all at once — far narrower exposure.
- Unverified secondary reports mention a fix in a branch aimed at Linux 7.5. That is not confirmed — do not plan around it.

## Full guide

https://thehomelabfixer.blogspot.com/2026/10/ksmbd-vulnerability-your-nas-runs-samba.html

By Bilal — The Glitch Fixer (https://theglitchfixer.blogspot.com/) and The Homelab Fixer (https://thehomelabfixer.blogspot.com/).
