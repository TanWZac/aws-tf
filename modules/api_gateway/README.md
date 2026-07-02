# API Gateway Module

This module provides an AWS API gateway layer in front of a platform backend.

It uses Amazon API Gateway HTTP API and proxies traffic to a backend HTTP endpoint, usually the platform ALB.

## Use Cases

- public API entry point
- frontend-to-backend API gateway
- CORS handling
- basic throttling
- access logging
- custom API domain
- future auth integration with JWT or Cognito

## Default Routes

```text
ANY /
ANY /{proxy+}
```

All routes are proxied to `backend_url`.

## Backend Example

```hcl
backend_url = "http://my-platform-alb.example.com"
```

## Notes

HTTP APIs are simpler and lower cost than REST APIs. REST APIs have more advanced API management features such as usage plans and API keys. For this platform template, HTTP API is a good default starting point.
