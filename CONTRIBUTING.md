# Contributing & Reproducing the Lab

This repository documents a personal, hands-on Wazuh SIEM lab. It is primarily a reference
and portfolio project, but improvements, corrections, and additional detection content are
welcome.

## Reproducing the lab

1. Stand up an isolated (host-only / internal) virtual network. **Do not expose the lab to the
   public internet.**
2. Install the Wazuh central components on a Linux VM — see
   [`docs/deployment-guide.md`](docs/deployment-guide.md) or run
   [`scripts/install_wazuh_server.sh`](scripts/install_wazuh_server.sh).
3. Enroll a Linux and a Windows agent with
   [`scripts/install_agent_linux.sh`](scripts/install_agent_linux.sh) and
   [`scripts/install_agent_windows.ps1`](scripts/install_agent_windows.ps1).
4. Apply the configuration snippets from [`config/`](config/) (FIM, auditd, custom rules and
   decoders), then restart the manager/agents.
5. Validate detection with [`scripts/simulate_attacks.sh`](scripts/simulate_attacks.sh) and
   confirm the alerts on the dashboard.

## Ground rules

- **Only test systems you own or are explicitly authorized to test.** The simulation scripts
  generate failed logins, file changes, and account activity purely to exercise detection
  rules in your own lab.
- Never commit real alerts, exported data, API credentials, certificates, or
  `wazuh-install-files.tar`. The [`.gitignore`](.gitignore) covers the common cases — double
  check before pushing.
- Redact hostnames, internal IPs, and usernames from any screenshots or logs you add.

## Submitting changes

- Open an issue describing the change first for anything non-trivial.
- Keep custom rules in `config/local_rules.xml` and decoders in `config/local_decoder.xml`,
  and document new detection logic in the matching file under `docs/`.
- Use clear, descriptive commit messages.
