# Proven Library Integration Plan

This document outlines how the [proven](https://github.com/hyperpolymath/proven) library's formally verified modules can be integrated into poly-cloud-mcp.

## Applicable Modules

### High Priority

| Module | Use Case | Formal Guarantee |
|--------|----------|------------------|
| `SafeCapability` | IAM permission modeling | Principle of least privilege |
| `SafeResource` | Cloud resource lifecycle | Valid state transitions |
| `SafePolicy` | Cloud policy enforcement | AST-level policy validation |

### Medium Priority

| Module | Use Case | Formal Guarantee |
|--------|----------|------------------|
| `SafeSchema` | API request/response validation | Type-safe cloud API calls |
| `SafeGraph` | Resource dependency graphs | Acyclic infrastructure |
| `SafeBuffer` | API rate limiting | Bounded request queues |

## Integration Points

### 1. IAM Capabilities (SafeCapability)

```
aws_iam_create_role → SafeCapability.createCapability → scoped Role
gcloud_iam_add_binding → SafeCapability.attenuate → reduced permissions
```

Capabilities follow the object-capability model:
- Create capabilities with specific resource access
- Attenuate (reduce) but never amplify permissions
- Revoke by dropping capability reference

### 2. Resource Lifecycle (SafeResource)

```
:nonexistent → :creating → :running → :stopping → :stopped → :terminated
```

Cloud resource state transitions:
- `aws_ec2_run_instances`: nonexistent → running
- `aws_ec2_stop_instances`: running → stopped
- `aws_ec2_terminate_instances`: * → terminated

### 3. Cloud Policy (SafePolicy)

```
SafePolicy.Zone.Restricted: PII data stores
SafePolicy.Zone.Immutable: Production databases
SafePolicy.Zone.Mutable: Development resources
```

Policy zones prevent accidental modifications to protected resources.

## Provider-Specific Integrations

| Provider | Key Integration | proven Module |
|----------|-----------------|---------------|
| AWS | IAM roles & policies | SafeCapability |
| GCP | IAM bindings | SafeCapability |
| Azure | RBAC | SafeCapability |
| Hetzner | Firewalls | SafePolicy |
| DigitalOcean | Projects | SafeResource |

## Implementation Notes

For CLI-based cloud tools, proven validates inputs before execution:

```
user_input → SafeSchema.validate → aws_cli_call → SafeResource.transition
```

This prevents invalid API calls and ensures state consistency.

## Status

- [ ] Add SafeCapability bindings for IAM operations
- [ ] Implement SafeResource for EC2/compute lifecycle
- [ ] Integrate SafePolicy for resource protection zones
- [ ] Add request validation via SafeSchema
