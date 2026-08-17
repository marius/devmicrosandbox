FROM node:26
COPY packages.txt /tmp/packages.txt
RUN apt-get update \
      && grep -v '^#' /tmp/packages.txt | xargs apt-get install -y --no-install-recommends \
      && rm -rf /var/lib/apt/lists/* /tmp/packages.txt \
      && npm install -g opencode-ai --allow-scripts=opencode-ai
