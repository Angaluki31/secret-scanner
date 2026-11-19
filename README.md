# Secret Scanner

A Bash pre-commit hook that scans staged changes and blocks the commit if it finds something that looks like a secret, such as an API key, token, private key or hardcoded password.

## Install into a repo

```bash
bash secretscan.sh install path/to/repo
```

From then on, every `git commit` in that repo is scanned automatically.

## Other commands

```bash
bash secretscan.sh scan                     # scan staged changes manually
bash secretscan.sh uninstall path/to/repo
```

## What it detects

| Type | Example pattern |
|------|-----------------|
| AWS access key | `AKIA` followed by 16 characters |
| Github token | `ghp_` followed by 36 characters |
| API secret key | `sk-` followed by 20+ characters |
| Private key | `-----BEGIN PRIVATE KEY-----` |
| Hardcoded password or token | `password = "..."`, `token: '...'` |

## False alarms

- Add `secretscan:ignore` to a line to skip it
- Bypass once with `git commit --no-verify`

The scanner never prints the secret itself, only the file and the type.

## Requirements

Bash and Git (Git Bash on Windows)