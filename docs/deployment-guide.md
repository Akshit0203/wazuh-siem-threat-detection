# Deployment Guide

Step-by-step install of the Wazuh central components and enrollment of Linux and Windows agents.
Everything here was run in an isolated lab. Scripts that automate these steps live in
[`../scripts/`](../scripts/).

> **Prerequisites** — a Linux VM for the server with ≥ 2 vCPU and 4 GB RAM (8 GB recommended),
> plus one or more endpoint VMs. Keep the whole lab on a host-only/internal network.

---

## 1. Install the Wazuh server (all-in-one)

The official quickstart installs the manager, indexer, and dashboard on one host.

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash ./wazuh-install.sh -a -i
```

When it finishes it prints the admin credentials and writes `wazuh-install-files.tar`.
Retrieve the dashboard password any time with:

```bash
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```

Open the dashboard at `https://<SERVER-IP>` and log in as **admin**. You'll land on the
**Modules** overview — see [`03-modules-overview.png`](../assets/images/03-modules-overview.png).

> Automated by [`../scripts/install_wazuh_server.sh`](../scripts/install_wazuh_server.sh).

---

## 2. Enroll a Linux agent

On the endpoint (Debian/Ubuntu example):

```bash
# Add the repo + key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.9/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update

# Install, passing the manager IP + a friendly agent name
sudo WAZUH_MANAGER="<SERVER-IP>" WAZUH_AGENT_NAME="ubuntuvm" apt-get install -y wazuh-agent

# Enable + start
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent

# For whodata FIM and System Auditing
sudo apt-get install -y auditd
```

The agent registers automatically and should appear as **Active** under **Agents**.

> Automated (Debian **and** RHEL) by
> [`../scripts/install_agent_linux.sh`](../scripts/install_agent_linux.sh):
> `sudo ./install_agent_linux.sh <SERVER-IP> ubuntuvm`

---

## 3. Enroll a Windows agent

In an **elevated** PowerShell on the Windows endpoint:

```powershell
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi" `
  -OutFile "$env:TEMP\wazuh-agent.msi"

msiexec.exe /i "$env:TEMP\wazuh-agent.msi" /q `
  WAZUH_MANAGER="<SERVER-IP>" WAZUH_AGENT_NAME="win-ep-01" WAZUH_REGISTRATION_SERVER="<SERVER-IP>"

Start-Service -Name WazuhSvc
```

> Automated by
> [`../scripts/install_agent_windows.ps1`](../scripts/install_agent_windows.ps1):
> `.\install_agent_windows.ps1 -ManagerIP <SERVER-IP> -AgentName win-ep-01`

---

## 4. Apply the lab configuration

**On the manager** — add the custom detection content, then restart:

```bash
sudo cp config/local_rules.xml    /var/ossec/etc/rules/local_rules.xml
sudo cp config/local_decoder.xml  /var/ossec/etc/decoders/local_decoder.xml
sudo /var/ossec/bin/wazuh-logtest     # optional: validate decoders/rules interactively
sudo systemctl restart wazuh-manager
```

**On each Linux agent** — merge the FIM/auditd/log blocks from
[`../config/ossec.conf.linux.xml`](../config/ossec.conf.linux.xml) into
`/var/ossec/etc/ossec.conf`, then:

```bash
sudo systemctl restart wazuh-agent
```

**On each Windows agent** — merge
[`../config/ossec.conf.windows.xml`](../config/ossec.conf.windows.xml) into
`C:\Program Files (x86)\ossec-agent\ossec.conf`, then `Restart-Service WazuhSvc`.

---

## 5. Verify

- **Agents** view shows each endpoint as **Active**.
- **Modules → Security Events** starts populating within a minute or two.
- Trigger a quick test from a Linux agent and watch the alerts:

```bash
sudo ./scripts/simulate_attacks.sh --all
```

See [threat-simulation.md](threat-simulation.md) for what each test should produce.
