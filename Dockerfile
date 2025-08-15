# ---- Stage 1: Build ----
FROM node:22.16 as builder

RUN corepack enable
RUN corepack prepare pnpm@10.12.1 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
COPY packages ./packages

ENV PNPM_DISABLE_CATALOG=true RUN pnpm install --frozen-lockfile
RUN pnpm build

# ---- Stage 2: Runtime ----
FROM node:22.16-slim

RUN corepack enable
RUN corepack prepare pnpm@10.12.1 --activate

WORKDIR /app

COPY --from=builder /app ./

RUN pnpm install --prod --frozen-lockfile

# Add gcsfuse for mounting GCS bucket
RUN apt-get update && apt-get install -y gcsfuse && rm -rf /var/lib/apt/lists/*

# Create directory for n8n data
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

USER node

EXPOSE 5678

# Mount GCS bucket to /home/node/.n8n before starting
ENTRYPOINT ["/bin/sh", "-c", "gcsfuse $GCS_BUCKET /home/node/.n8n && n8n start"]
