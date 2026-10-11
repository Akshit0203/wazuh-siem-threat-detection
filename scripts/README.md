# Scripts

Helper scripts for standing up the lab and validating detection. All are for use in an
**isolated lab on systems you own or are authorized to test**.

| Script | Platform | Purpose |
|---|---|---|
| [`install_wazuh_server.sh`](install_wazuh_server.sh) | Linux (server) | All-in-one install of manager + indexer + dashboard via the Wazuh quickstart. |
| [`install_agent_linux.sh`](install_agent_linux.sh) | Linux (endpoint) | Install + enroll a Wazuh agent (Debian/Ubuntu or RHEL/CentOS). |
| [`install_agent_windows.ps1`](install_agent_windows.ps1) | Windows (endpoint) | Install + enroll a Wazuh agent (elevated PowerShell). |
| [`simulate_attacks.sh`](simulate_attacks.sh) | Linux (agent) | Generate benign attack-like activity (SSH brute force, FIM changes, account create/delete) to confirm alerts fire. |

## Order of operations

```bash
# 1) On the Linux server VM
sudo ./install_wazuh_server.sh

# 2) On each Linux endpoint
sudo ./install_agent_linux.sh <MANAGER_IP> <AGENT_NAME>

# 3) On each Windows endpoint (elevated PowerShell)
.\install_agent_windows.ps1 -ManagerIP <MANAGER_IP> -AgentName <AGENT_NAME>

# 4) Apply config/ (rules + decoders on the manager, FIM/audit on agents), restart services

# 5) Validate detection from a Linux agent
sudo ./simulate_attacks.sh --all
```

## Notes

- `install_*` scripts take the Wazuh version as an optional last argument (default `4.9`).
- `simulate_attacks.sh` is a **detection test**, not an exploit. It only acts on the local
  machine (failed logins to `127.0.0.1`, files under `/data`, a throwaway local user) so you
  can see the corresponding alerts on the dashboard.
- Review each script before running it, and never point the installers or simulation at a host
  you do not own.
