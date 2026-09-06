#!/bin/bash
set -euo pipefail

# apt packages from packages.txt (skip comments)
apt-get update
grep -v '^#' /tmp/packages.txt | xargs apt-get install -y --no-install-recommends
rm -rf /var/lib/apt/lists/* /tmp/packages.txt

# Global npm agents
npm install -g --allow-scripts=opencode-ai opencode-ai
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Herdr + integrations
curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin sh
mkdir -p /root/.agents/skills/herdr /root/.pi/agent/extensions /root/.pi/agent/skills
herdr integration install opencode
herdr integration install pi
curl -fsSL -o /root/.agents/skills/herdr/SKILL.md \
     https://raw.githubusercontent.com/herdrdev/herdr/master/skills/herdr/SKILL.md
ln -s /root/.agents/skills/herdr /root/.pi/agent/skills/herdr

# OKF CLI
curl -fsSL -o /usr/local/bin/okf \
     https://github.com/okf-memory/okf-agent-memory/releases/latest/download/okf-linux-amd64
chmod +x /usr/local/bin/okf
