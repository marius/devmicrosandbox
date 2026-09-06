FROM node:26
COPY packages.txt setup.sh /tmp/
RUN bash /tmp/setup.sh
