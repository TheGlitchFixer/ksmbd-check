#!/usr/bin/env bash
# ksmbd-check — 30-second check: is KSMBD (the Linux kernel SMB server) running?
# The two CVSS 9.0 flaws ZDI-CAN-33774 and ZDI-CAN-33549 (disclosed Oct 22, 2026)
# affect KSMBD only — NOT normal userspace Samba. This script tells you which
# SMB server your box actually runs, and whether port 445 is listening.
# Usage: bash ksmbd-check.sh   (no root needed for the read-only checks;
#                               ss may show less detail without root)
set -u

echo "== KSMBD check =="
echo

# 1. Is the ksmbd kernel module loaded?
if command -v lsmod >/dev/null 2>&1; then
    if lsmod 2>/dev/null | grep -q '^ksmbd'; then
        echo "[!] ksmbd kernel module is LOADED."
        KSMBD_LOADED=1
    else
        echo "[OK] ksmbd kernel module is NOT loaded."
        KSMBD_LOADED=0
    fi
else
    echo "[?] lsmod not found — cannot check the kernel module."
    KSMBD_LOADED=0
fi

# 2. Is a ksmbd service active?
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet ksmbd 2>/dev/null; then
        echo "[!] ksmbd service is ACTIVE."
        KSMBD_ACTIVE=1
    else
        echo "[OK] ksmbd service is not active."
        KSMBD_ACTIVE=0
    fi
else
    echo "[?] systemctl not found — skipping service check."
    KSMBD_ACTIVE=0
fi

# 3. Is anything listening on port 445 (SMB)?
if command -v ss >/dev/null 2>&1; then
    LISTEN445=$(ss -tln 2>/dev/null | awk '$4 ~ /:445$/')
    if [ -n "$LISTEN445" ]; then
        echo "[!] Something is listening on port 445:"
        echo "$LISTEN445"
    else
        echo "[OK] Nothing is listening on port 445."
    fi
elif command -v netstat >/dev/null 2>&1; then
    if netstat -tln 2>/dev/null | grep -q ':445 '; then
        echo "[!] Something is listening on port 445."
    else
        echo "[OK] Nothing is listening on port 445."
    fi
else
    echo "[?] Neither ss nor netstat found — cannot check port 445."
fi

# 4. Is normal Samba running? (Samba is NOT affected by these two flaws.)
echo
echo "-- Normal Samba (not affected) --"
if command -v systemctl >/dev/null 2>&1; then
    for svc in smbd smb nmbd; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "[i] $svc service is active — normal userspace Samba."
        fi
    done
fi
if pgrep -x smbd >/dev/null 2>&1; then
    echo "[i] smbd process is running — normal userspace Samba."
fi

echo
echo "== Verdict =="
if [ "${KSMBD_LOADED:-0}" = "1" ] || [ "${KSMBD_ACTIVE:-0}" = "1" ]; then
    echo "KSMBD IS running on this box. You are in scope for ZDI-CAN-33774 / ZDI-CAN-33549."
    echo "Stop the ksmbd service / unload the module, or block inbound port 445 at your firewall."
    echo "Full guide: https://thehomelabfixer.blogspot.com/2026/10/ksmbd-vulnerability-your-nas-runs-samba.html"
else
    echo "KSMBD is NOT running on this box. The two KSMBD flaws do not affect you."
    echo "If you run normal Samba, you are not affected either."
fi
