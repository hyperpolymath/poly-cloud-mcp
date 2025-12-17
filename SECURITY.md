# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously at poly-cloud-mcp. If you discover a security vulnerability, please follow responsible disclosure practices.

### How to Report

1. **Email**: Send details to [security@hyperpolymath.org](mailto:security@hyperpolymath.org)
2. **Encrypted Communication**: Use our PGP key available at https://hyperpolymath.org/gpg/security.asc
3. **Do NOT** create public GitHub issues for security vulnerabilities

### What to Include

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes (optional)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution Target**: Within 30 days for critical issues

### Security Measures

This project implements several security practices:

- **Signed Commits**: All commits are GPG-signed
- **Minimal Permissions**: Container runs as non-root user (UID 1000)
- **Secure Base Image**: Uses Chainguard Wolfi base image
- **Pinned Dependencies**: GitHub Actions use SHA-pinned versions
- **No Credential Storage**: Credentials are passed via environment variables only
- **Input Validation**: All tool inputs are validated before execution

### Scope

Security reports are accepted for:

- The poly-cloud-mcp server code
- Container image vulnerabilities
- CI/CD pipeline security issues
- Documentation security errors

Out of scope:

- Vulnerabilities in underlying cloud provider CLIs (aws, gcloud, az, doctl)
- Issues in the Deno runtime itself
- Social engineering attacks

### Recognition

We maintain an acknowledgments page for security researchers who responsibly disclose vulnerabilities:
https://hyperpolymath.org/security/acknowledgments

## Security Best Practices for Users

1. **Credential Security**: Never commit cloud credentials. Use environment variables or mounted config files.
2. **Network Isolation**: Run the MCP server in a network-isolated environment when possible.
3. **Least Privilege**: Configure cloud CLI credentials with minimal required permissions.
4. **Audit Logs**: Enable cloud provider audit logging for operations performed via this tool.
5. **Update Regularly**: Keep the container image and cloud CLIs updated.
