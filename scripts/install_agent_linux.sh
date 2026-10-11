#!/usr/bin/env bash
#
# install_agent_linux.sh
# Install and enroll a Wazuh agent on a Linux endpoint (Debian/Ubuntu or RHEL/CentOS).
# Run as root (or with sudo) on the ENDPOINT you want to monitor.
#
# Usage:
#   sudo ./install_agent_linux.sh <MANAGER_IP> [AGENT_NAME] [WAZUH_VERSION]
#
# Example:
#   sudo ./install_agent_linux.sh 192.168.56.10 ubuntuvm 4.9
#
# Docs: https://documentation.wazuh.com/current/installation-guide/wazuh-agent/
set -euo pipefail

MANAGER_IP="${1:-}"
AGENT_NAME="${2:-$(hostname)}"
WAZUH_VERSION="${3:-4.9}"

if [[ -z "$MANAGER_IP" ]]; then
  echo "Usage: sudo $0 <MANAGER_IP> [AGENT_NAME] [WAZUH_VERSION]" >&2
  exit 1
fi
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] Please run as root (sudo)." >&2
  exit 1
fi

echo "[*] Installing Wazuh agent v${WAZUH_VERSION} (manager=${MANAGER_IP}, name=${AGENT_NAME}) ..."

if command -v apt-get >/dev/null 2>&1; then
  # ---- Debian / Ubuntu ----
  apt-get install -y curl gnupg apt-transport-https lsb-release
  curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
    | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
  chmod 644 /usr/share/keyrings/wazuh.gpg
  echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" \
    > /etc/apt/sources.list.d/wazuh.list
  apt-get update
  WAZUH_MANAGER="$MANAGER_IP" WAZUH_AGENT_NAME="$AGENT_NAME" apt-get install -y wazuh-agent

elif command -v yum >/dev/null 2>&1; then
  # ---- RHEL / CentOS ----
  rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
  cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/${WAZUH_VERSION}/yum/
protect=1
EOF
  WAZUH_MANAGER="$MANAGER_IP" WAZUH_AGENT_NAME="$AGENT_NAME" yum install -y wazuh-agent
else
  echo "[!] Unsupported package manager (need apt-get or yum)." >&2
  exit 1
fi

echo "[*] Enabling and starting the agent ..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# For auditd 'whodata' FIM and System Auditing, make sure auditd is present
if ! command -v auditctl >/dev/null 2>&1; then
  echo "[*] Installing auditd (needed for whodata FIM and System Auditing) ..."
  (apt-get install -y auditd || yum install -y audit) || true
fi

echo "[+] Done. Confirm the agent shows as 'Active' on the dashboard (Agents view)."
echo "    Then apply config/ossec.conf.linux.xml blocks and: sudo systemctl restart wazuh-agent"
