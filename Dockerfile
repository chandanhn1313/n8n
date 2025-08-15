# ---- Stage 1: Build ----
FROM node:20 as builder

# Enable pnpm
RUN corepack enable

# Set workdir
WORKDIR /app

# Copy package manager files
COPY package.json pnpm-lock.yaml ./
COPY packages ./packages

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build all packages
RUN pnpm build

# ---- Stage 2: Runtime ----
FROM node:20-slim

WORKDIR /app

# Copy built files from builder
COPY --from=builder /app ./

# Install production deps only
RUN pnpm install --prod --frozen-lockfile

# Expose n8n port
EXPOSE 5678

# Default command
CMD ["n8n", "start"]
