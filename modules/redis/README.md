# Redis Module

This module provisions an AWS ElastiCache Redis replication group for platform services.

## Use Cases

- API response caching
- session storage
- distributed locks
- background job coordination
- rate limiting
- short-lived AI/RAG intermediate state

## Security Model

Redis is deployed into private subnets. Inbound access is allowed only from the supplied workload security groups.

## Defaults

- Engine: Redis
- Port: 6379
- Node type: cache.t4g.micro
- Encryption at rest: enabled
- Encryption in transit: enabled
- Snapshot retention: 7 days

## Production Notes

For production, use at least two nodes so automatic failover and multi-AZ placement are enabled.

Set `auth_token` from a secret store rather than hardcoding it in tfvars.
