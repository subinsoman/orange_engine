# Copyright (c) 2016, CodiLime Inc.
FROM  node:14-bullseye-slim

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/docker
WORKDIR /opt/docker

COPY package.json .
RUN npm config set registry http://registry.npmjs.org/ && npm install

COPY . .
# TODO Building should occur before ever adding js files as docker layer (or we should squash some layers)
# Otherwise someone might access source code
RUN npm run build && \
    rm -rf app

CMD ["npm", "start"]
