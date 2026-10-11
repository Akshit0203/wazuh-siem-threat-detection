#!/usr/bin/env bash
#
# simulate_attacks.sh
# Detection-validation harness for the Wazuh lab. Generates benign, self-contained
# "attack-like" activity on the LOCAL machine so you can confirm the matching Wazuh
# alerts fire on the dashboard. Nothing here touches another host or exfiltrates data.
#
#   * SSH brute force  -> failed logins against localhost      (rules 5710/5716/100110)
#   * FIM tampering     -> add/modify/delete files in /data     (syscheck 550/553/554)
#   * Account activity  -> create and delete a throwaway user   (audit: useradd/userdel)
#
# >>> AUTHORIZATION <<<
# Run ONLY on a lab machine you own. This is for testing your own detections, not for
# use against systems you do not control. Run as root (sudo) on a Linux AGENT host.
#
# Usage:  sudo ./simulate_attacks.sh [--ssh] [--fim] [--audit] [--all]
set -euo pipefail

TARGET="127.0.0.1"
FIM_DIR="/data"
TEST_USER="fimtest_$$"

run_ssh=false; run_fim=false; run_audit=false
if [[ $# -eq 0 ]]; then run_ssh=true; run_fim=true; run_audit=true; fi
for arg in "$@"; do
  case "$arg" in
    --ssh) run_ssh=true ;;
    --fim) run_fim=true ;;
    --audit) run_audit=true ;;
    --all) run_ssh=true; run_fim=true; run_audit=true ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] Please run as root (sudo)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1) SSH brute force -> authentication_failures (MITRE T1110)
#    Uses sshpass with deliberately wrong passwords against localhost.
# ---------------------------------------------------------------------------
simulate_ssh() {
  echo "[*] Simulating SSH brute force against ${TARGET} (10 failed logins) ..."
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "    sshpass not found; install it (apt install sshpass / yum install sshpass) or"
    echo "    run this loop manually. Skipping."
    return 0
  fi
  for i in $(seq 1 10); do
    sshpass -p "wrong-password-${i}" \
      ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
      "nosuchuser@${TARGET}" "true" 2>/dev/null || true
  done
  echo "    -> Expect a burst under Security Events (auth failures, SSH/Password Guessing)."
}

# ---------------------------------------------------------------------------
# 2) FIM tampering -> syscheck add/modify/delete (requires /data in syscheck)
# ---------------------------------------------------------------------------
simulate_fim() {
  echo "[*] Simulating file integrity changes in ${FIM_DIR} ..."
  mkdir -p "${FIM_DIR}"
  echo "created $(date)"  >  "${FIM_DIR}/test.txt"     # added
  echo "appended line"    >> "${FIM_DIR}/test.txt"     # modified
  echo "temp"             >  "${FIM_DIR}/test2.txt"
  rm -f "${FIM_DIR}/test2.txt"                          # deleted
  echo "    -> Expect added/modified/deleted events under Integrity Monitoring."
}

# ---------------------------------------------------------------------------
# 3) Account activity -> audit: useradd / userdel, /etc/passwd + /etc/shadow
# ---------------------------------------------------------------------------
simulate_audit() {
  echo "[*] Simulating account create/delete (user: ${TEST_USER}) ..."
  useradd "${TEST_USER}" 2>/dev/null || true
  userdel "${TEST_USER}" 2>/dev/null || true
  echo "    -> Expect useradd/userdel commands under System Auditing."
}

$run_ssh   && simulate_ssh
$run_fim   && simulate_fim
$run_audit && simulate_audit

echo
echo "[+] Simulation complete. Open the Wazuh dashboard -> Security Events / Integrity"
echo "    Monitoring / System Auditing and set the time range to 'Last 15 minutes'."
