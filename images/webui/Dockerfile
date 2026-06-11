# syntax=docker/dockerfile:1
ARG NODE_VERSION="20"

# --- STAGE 1: Builder ---
FROM node:${NODE_VERSION}-bookworm AS builder

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

ARG OPEN5GS_VERSION="v2.7.6"
WORKDIR /webui
COPY ./webui . 
RUN npm ci && npm run build

RUN ls -R /webui/.next

# --- STAGE 2: Runtime (Production) ---
FROM node:${NODE_VERSION}-bookworm-slim

RUN groupadd -r open5gs && useradd -r -g open5gs open5gs

WORKDIR /usr/local/src/webui

COPY --from=builder /webui/.next ./.next
COPY --from=builder /webui/server ./server
COPY --from=builder /webui/static ./static
COPY --from=builder /webui/pages ./pages
COPY --from=builder /webui/src ./src
COPY --from=builder /webui/package*.json ./

COPY --from=builder /webui/.babelrc ./

RUN chown -R open5gs:open5gs /usr/local/src/webui

RUN npm ci --only=production

ENV DB_URI="mongodb://db/open5gs"
ENV HOSTNAME="0.0.0.0"
ENV PORT=9999
ENV NODE_ENV="production"

USER open5gs

ENTRYPOINT ["node", "server/index.js"]