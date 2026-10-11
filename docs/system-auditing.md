# System Auditing

The **System Auditing** module integrates Wazuh with the Linux **Audit** subsystem (`auditd`)
to track user behaviour, command execution, and access to critical files — exactly the activity
you need for insider-threat detection, privilege-abuse monitoring, and compliance audit trails.

<p align="center">
  <img src="../assets/images/06-system-auditing.png" alt="System Auditing dashboard by group, agent, command and file" width="880">
</p>

## How it works

- `auditd` logs kernel-level events based on **audit rules** you define (syscalls, file watches,
  command execution).
- Wazuh reads the audit stream, decodes it, and matches it against its `audit` rule group.
- The dashboard then aggregates the alerts by **group**, **agent**, **command**, and **file**.

`auditd` must be installed on the agent (the installer script does this). The same mechanism
also powers `whodata` FIM — see [file-integrity-monitoring.md](file-integrity-monitoring.md).

## Example audit rules

Add these with `auditctl` (runtime) or persist them in `/etc/audit/rules.d/wazuh.rules`:

```bash
# Watch sensitive account/authentication files for writes & attribute changes
-w /etc/passwd  -p wa -k identity
-w /etc/shadow  -p wa -k identity
-w /etc/group   -p wa -k identity
-w /etc/sudoers -p wa -k priv_esc

# Log account-management commands
-w /usr/sbin/useradd -p x -k account_mgmt
-w /usr/sbin/userdel -p x -k account_mgmt
-w /usr/sbin/usermod -p x -k account_mgmt

# Monitor a sensitive directory for all access (example)
-w /data -p rwxa -k data_access
```

Reload: `sudo augenrules --load` (or `sudo service auditd restart`).

## What the dashboard shows

In the lab the module breaks audit activity down into clear panels:

- **Groups** — the `audit` rule group.
- **Agents** — mostly `centosvm`, with some events on `wazuh-server`.
- **Commands** — `useradd`, `userdel`, `pam_tally2`, `wazuh-agentd`, `nroff` …
- **Files** — `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow` …
- **Alerts over time** — spikes line up with the account-management test activity.

This gives immediate visibility into *who ran what* and *which sensitive files were touched* —
the backbone of an audit trail.

## Testing

```bash
sudo ./scripts/simulate_attacks.sh --audit
```

This creates and deletes a throwaway local user, which triggers `useradd`/`userdel` command
auditing and writes to `/etc/passwd` and `/etc/shadow`. Confirm the events under **System
Auditing** (time range: Last 15 minutes). See [threat-simulation.md](threat-simulation.md).

## Compliance tie-in

Audit trails on sensitive files and privileged actions map directly to **PCI DSS 10.2.x**
(audit trails) and **10.6.1** (log review). The audit events populate those requirements in the
PCI DSS dashboard — see [compliance-pci-dss.md](compliance-pci-dss.md).
