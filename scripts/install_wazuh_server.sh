#!/usr/bin/env bash
#
# install_wazuh_server.sh
# All-in-one install of the Wazuh central components (manager + indexer + dashboard)
# using the official Wazuh quickstart installer. Single-node lab deployment.
#
# Tested target: Ubuntu 22.04 / CentOS 8 VM with >= 2 vCPU, 4 GB RAM (8 GB recommended).
# Run as root (or with sudo). Do NOT expose this host to the public internet.
#
# Docs: https://documentation.wazuh.com/current/quickstart.html
set -euo pipefail

WAZUH_VERSION="4.9"   # change to the version you want

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] Please run as root (sudo)." >&2
  exit 1
fi

echo "[*] Downloading the Wazuh installer (v${WAZUH_VERSION}) ..."
curl -sO "https://packages.wazuh.com/${WAZUH_VERSION}/wazuh-install.sh"

echo "[*] Running all-in-one installation (this takes several minutes) ..."
bash ./wazuh-install.sh -a -i

cat <<'EOF'

[+] Installation finished.

    The admin password and the full set of credentials were printed above and are also
    stored (encrypted) in:  wazuh-install-files.tar

    Retrieve the 'admin' dashboard password at any time with:
        sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt

    Access the dashboard:
        https://<THIS-HOST-IP>      (user: admin)

    Next steps:
      - Enroll a Linux agent:   scripts/install_agent_linux.sh
      - Enroll a Windows agent: scripts/install_agent_windows.ps1
      - Apply custom rules/decoders from config/ on this manager, then:
            sudo systemctl restart wazuh-manager

    KEEP wazuh-install-files.tar PRIVATE — it is already covered by .gitignore.
EOF
