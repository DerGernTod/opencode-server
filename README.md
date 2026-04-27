# OpenCode Server with Authelia authentication reverse proxy

This setup allows you to run an OpenCode server behind an authelia authentication reverse proxy.

## How-to

* Set up your domain server to support `auth.your-domain.com` and `opencode.your-domain.com` (pointing to the server hosting this docker-compose file).
* Check out this repo
* Rename all *-template files (remove the `-template`)
* Populate the (formerly template) files with your data (domain, username, project path)
* Build with `docker compose build`
* Run with `docker compose up -d`

### First login

Before being authenticated, you'll be redirected to the auth server. Log in with the credentials you chose. Setting up 2-FA requires you to generate a code.
This code is not sent to you by E-Mail, but instead is stored in `./authelia/notification.txt` - once inserted, the client prompts you for the passkey to add to your account.

By default, authelia will redirect you to `opencode.your-domain.com` after successful login. If you want to change your credential setup, just visit `auth.your-domain.com`
and you'll see the authelia UI.

### Setting up opencode projects

OpenCode launches in root. Within the opencode UI, you can bring up a terminal where you can navigate to your projects and launch opencode _once_, so that it stores it.
From that point on, you can refresh the page and select the project you just initialized.

# PR Review Factory: Infrastructure & Setup Guide

This document summarizes the manual configurations and infrastructure logic required to run the PR Preview system. This information is **not** reflected in the `docker-compose.yml`
or `Caddyfile` but is critical for a fresh server setup or migrating to a new domain/repository.

---

## 1. Windows OpenSSH Server Setup (The "Admin" Fix)

Standard Linux SSH logic often fails on Windows due to how permissions and the `administrators` group are handled.

### The Authorized Keys Path
By default, Windows OpenSSH ignores `~/.ssh/authorized_keys` for users in the Administrators group. You must use the global configuration:
1.  **File Location:** `C:/ProgramData/ssh/administrators_authorized_keys`
2.  **Permissions (Critical):** - Right-click the file -> **Properties** -> **Security** -> **Advanced**.
    - **Disable Inheritance.**
    - Choose "Remove all inherited permissions from this object."
    - Manually add **SYSTEM** and the **Administrators** group with **Full Control**.
    - **Note:** If any other user (including your specific user account) has explicit permissions, the SSH service will reject the key for being "too open."

### SSH Service Configuration
Ensure the following is set at the very bottom of `C:/ProgramData/ssh/sshd_config`:
```ssh
Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```
Restart the `OpenSSH SSH Server` service after changes.

---

## 2. Domain & DNS Infrastructure (Hetzner Cloud)

The system relies on the **Hetzner Cloud DNS API (v2)**.

### Manual DNS Record Setup
- **Type:** `A`
- **Name:** `*.prs`
- **Value:** Your server's Public IP address.
- **Note:** This allows `pr42-app.prs.your-domain.com` to resolve to your server.

### API Token Generation
1. Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/).
2. Select your Project, then go to **Security > API Tokens**.
3. Generate a **Personal Access Token** with **Read & Write** permissions.
4. Place this in your `.env` file as `HETZNER_API_KEY`.

---

## 3. Server-Side Infrastructure

### Shared Docker Network
The Caddy container and PR containers must share a virtual bridge to resolve each other by name. Make sure to use this network interface in your project's Dockerfile.

### Firewall Requirements
Ensure your router and Windows Firewall (Advanced Settings -> Inbound Rules) allow:
- **Port 80/443:** Web traffic and SSL challenges.
- **Port 22:** GitHub Actions deployment via SSH.

---

## 4. GitHub Secrets & Actions

To enable deployment, set these **Repository Secrets** in GitHub:
- `SSH_HOST`: Server Public IP.
- `SSH_USER`: Your Windows username.
- `SSH_KEY`: The private key corresponding to the one in `administrators_authorized_keys`.

### Deployment Logic
The Action uses Docker Contexts to talk to the server over SSH:
`docker context create home-server --docker "host=ssh://${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }}"`

---

## 5. Scaling to New Repositories

### URL & Container Naming Convention
To keep the automation working, follow this naming pattern:
1. **GitHub Action:** `--name pr-${{ github.event.number }}-{repo-name}`
2. **Caddyfile Regex:** `^pr([0-9]+)-([a-z0-9-]+)\.prs`
3. **Resulting URL:** `https://pr42-my-app.prs.your-domain.com`

### Authelia Access Control
New sub-subdomains must be matched in Authelia's `configuration.yml`:
```yaml
access_control:
  default_policy: deny
  rules:
    - domain: "*.prs.your-domain.com"
      policy: two_factor
```

---

## 6. Troubleshooting Logic

- **SSL Errors:** Check `docker logs caddy`. If 404/403 occurs during the DNS challenge, verify the token is a **Cloud** token (api.hetzner.cloud), not a **Legacy DNS** token.
- **403 Forbidden:** This is almost always **Authelia**. Check if the domain is matched in `access_control`. If the page is blank, check the Caddyfile regex.
- **Connection Refused (SSH):** Check if the `administrators_authorized_keys` file has inheritance disabled and *only* SYSTEM/Admins have access.
- **502 Bad Gateway:** The container is running, but the Bun/Hono app is either crashed or listening on `127.0.0.1` (it must be `0.0.0.0`).