# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

FROM cgr.dev/chainguard/wolfi-base:latest

LABEL org.opencontainers.image.title="poly-cloud-mcp"
LABEL org.opencontainers.image.description="Unified MCP server for multi-cloud CLI: AWS, GCP, Azure, DigitalOcean, Hetzner"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="Jonathan D.A. Jewell"
LABEL org.opencontainers.image.source="https://github.com/hyperpolymath/poly-cloud-mcp"
LABEL org.opencontainers.image.licenses="MIT"
LABEL dev.mcp.server="true"
LABEL io.modelcontextprotocol.server.name="io.github.hyperpolymath/poly-cloud-mcp"

# Install Deno and cloud CLIs
RUN apk add --no-cache deno ca-certificates

# Create non-root user
RUN adduser -D -u 1000 mcp
WORKDIR /app

# Copy application files
COPY --chown=mcp:mcp deno.json package.json ./
COPY --chown=mcp:mcp main.js ./
COPY --chown=mcp:mcp lib/ ./lib/
COPY --chown=mcp:mcp src/ ./src/ 2>/dev/null || true

# Cache dependencies
RUN deno cache main.js || true

# Switch to non-root user
USER mcp

# Cloud credentials via environment or mounted config
ENV AWS_CONFIG_FILE=/home/mcp/.aws/config
ENV GOOGLE_APPLICATION_CREDENTIALS=/home/mcp/.config/gcloud/credentials.json
ENV AZURE_CONFIG_DIR=/home/mcp/.azure

ENTRYPOINT ["deno", "run", "--allow-run", "--allow-read", "--allow-write", "--allow-env", "--allow-net", "main.js"]
