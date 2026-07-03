# Redis / ElastiCache

This platform template includes an optional Redis module backed by AWS ElastiCache.

## Enable Redis

```hcl
enable_redis = true
```

## Common Development Settings

```hcl
enable_redis     = true
redis_node_type  = "cache.t4g.micro"
redis_node_count = 1
```

## Common Production Settings

```hcl
enable_redis     = true
redis_node_type  = "cache.t4g.small"
redis_node_count = 2
```

When `redis_node_count` is greater than 1, the module enables automatic failover and multi-AZ placement.

## Application Environment Variables

Pass these values to your application service:

```bash
REDIS_HOST=<redis_primary_endpoint>
REDIS_PORT=6379
REDIS_SSL=true
```

If auth is enabled:

```bash
REDIS_PASSWORD=<secret-value>
```

## Recommended Use Cases

- API response cache
- short-lived session state
- distributed locks
- rate limiting
- job coordination
- temporary AI/RAG intermediate state

## Security Notes

Redis is deployed into private subnets and only accepts inbound traffic from platform workload security groups.

Do not hardcode `redis_auth_token` in committed tfvars. Use a secret-backed workflow for real environments.
