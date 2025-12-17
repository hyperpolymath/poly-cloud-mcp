# poly-cloud-mcp Roadmap

## Current Status: v1.0.0 (Stable)

This document outlines the development roadmap for poly-cloud-mcp, a unified MCP server for multi-cloud provider management.

---

## Completed (v1.0.0)

### Core Infrastructure
- [x] ReScript-to-JavaScript compilation pipeline
- [x] Deno runtime integration
- [x] MCP protocol implementation (v2024-11-05)
- [x] stdio transport support
- [x] Tool routing by provider prefix

### Cloud Provider Adapters
- [x] **AWS** (13 tools): S3, EC2, Lambda, IAM, STS, CloudWatch, RDS, ECS
- [x] **Google Cloud** (12 tools): Compute Engine, Cloud Storage, Functions, Run, SQL, GKE
- [x] **Azure** (12 tools): VMs, Storage, Web Apps, Functions, AKS, SQL
- [x] **DigitalOcean** (13 tools): Droplets, Kubernetes, Databases, Spaces, Apps, Domains

### Security & Compliance
- [x] SPDX license headers on all source files
- [x] Chainguard Wolfi secure base image
- [x] Non-root container execution
- [x] GitHub Actions with SHA-pinned dependencies
- [x] RSR (Rhodium Standard Repositories) compliance
- [x] security.txt (RFC 9116)
- [x] AI Boundary Declaration Policy (AIBDP 0.2)
- [x] Consent-Aware HTTP implementation
- [x] Provenance metadata

---

## Roadmap v1.1 - Enhanced Functionality

### New Cloud Provider Support
- [ ] **Hetzner Cloud** - European cloud provider (hcloud CLI)
- [ ] **Linode/Akamai** - Cloud infrastructure (linode-cli)
- [ ] **Vultr** - High-performance cloud (vultr-cli)

### AWS Enhancements
- [ ] `aws_dynamodb_*` - DynamoDB table operations
- [ ] `aws_sns_*` - SNS topic/subscription management
- [ ] `aws_sqs_*` - SQS queue operations
- [ ] `aws_route53_*` - DNS management
- [ ] `aws_secretsmanager_*` - Secrets retrieval

### GCP Enhancements
- [ ] `gcloud_pubsub_*` - Pub/Sub topics and subscriptions
- [ ] `gcloud_firestore_*` - Firestore operations
- [ ] `gcloud_bigquery_*` - BigQuery dataset/table management
- [ ] `gcloud_dns_*` - Cloud DNS management

### Azure Enhancements
- [ ] `az_keyvault_*` - Key Vault secrets
- [ ] `az_cosmosdb_*` - CosmosDB operations
- [ ] `az_eventhub_*` - Event Hubs management
- [ ] `az_dns_*` - Azure DNS zones

### DigitalOcean Enhancements
- [ ] Fix `doctl_spaces_list` - Proper Spaces API integration
- [ ] `doctl_firewall_*` - Firewall rule management
- [ ] `doctl_vpc_*` - VPC management
- [ ] `doctl_monitoring_*` - Monitoring alerts

---

## Roadmap v1.2 - Developer Experience

### Testing & Quality
- [ ] Unit tests for all adapters
- [ ] Integration tests with mock CLIs
- [ ] GitHub Actions CI/CD test pipeline
- [ ] Code coverage reporting
- [ ] Automated security scanning (Trivy, Grype)

### Documentation
- [ ] Tool usage examples for each adapter
- [ ] MCP client configuration guides
- [ ] Troubleshooting guide
- [ ] API reference documentation

### Configuration
- [ ] Multi-region support per provider
- [ ] Profile/credential switching
- [ ] Environment-based configuration
- [ ] Tool filtering (enable/disable specific tools)

---

## Roadmap v1.3 - Advanced Features

### Multi-Cloud Operations
- [ ] Cross-provider resource tagging
- [ ] Unified cost estimation tool
- [ ] Multi-cloud status dashboard tool
- [ ] Resource comparison across providers

### Security Enhancements
- [ ] SBOM (Software Bill of Materials) generation
- [ ] Signed container images (cosign)
- [ ] VEX (Vulnerability Exploitability eXchange) documents
- [ ] Attestation support

### Performance
- [ ] Connection pooling for CLI invocations
- [ ] Response caching for read-only operations
- [ ] Parallel tool execution support
- [ ] Streaming responses for large outputs

---

## Roadmap v2.0 - Architecture Evolution

### Protocol Enhancements
- [ ] HTTP/SSE transport support
- [ ] WebSocket transport support
- [ ] Resource streaming
- [ ] Prompt templates for common operations

### Native SDK Integration
- [ ] AWS SDK direct integration (optional, alongside CLI)
- [ ] Google Cloud client libraries
- [ ] Azure SDK integration
- [ ] Rate limiting and retry logic

### Observability
- [ ] OpenTelemetry integration
- [ ] Structured logging (JSON)
- [ ] Metrics export (Prometheus format)
- [ ] Distributed tracing support

---

## Contributing

Contributions are welcome! Priority areas:
1. New cloud provider adapters
2. Additional tools for existing adapters
3. Test coverage improvements
4. Documentation enhancements

See [SECURITY.md](./SECURITY.md) for security-related contributions.

---

## Version History

| Version | Date       | Highlights                                    |
|---------|------------|-----------------------------------------------|
| 1.0.0   | 2025-12-16 | Initial release: AWS, GCP, Azure, DigitalOcean |
| 1.0.1   | 2025-12-17 | Security fixes, SPDX compliance, SECURITY.md   |
