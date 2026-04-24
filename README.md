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
