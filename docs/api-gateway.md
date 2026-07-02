# API Gateway

This platform template includes an optional Amazon API Gateway layer in front of the backend application service.

This is the AWS equivalent of an API management entry point for the platform.

## Enable API Gateway

```hcl
enable_api_gateway = true
```

API Gateway is enabled only when the app service is also enabled:

```hcl
enable_app_service = true
enable_api_gateway = true
```

## What It Provides

- managed API entry point
- HTTP proxy to the platform ALB
- CORS configuration
- default throttling
- CloudWatch access logs
- optional custom API domain

## Default Routing

```text
ANY /
ANY /{proxy+}
```

Requests are proxied to the app service ALB.

## Example Frontend Configuration

Use this output as the frontend API base URL:

```bash
NEXT_PUBLIC_API_BASE_URL=<api_gateway_endpoint>
```

## Example Settings

```hcl
enable_api_gateway = true

api_gateway_allowed_origins = [
  "https://app.example.com"
]

api_gateway_throttling_burst_limit = 200
api_gateway_throttling_rate_limit  = 100
```

## Custom Domain

```hcl
api_gateway_custom_domain_name = "api.example.com"
api_gateway_certificate_arn    = "arn:aws:acm:ap-southeast-2:123456789012:certificate/example"
```

Create the Route 53 alias record to the API Gateway domain target as part of your DNS layer.

## Notes

HTTP APIs are a good default for platform APIs because they are simple and cost-effective.

Use REST APIs if you need advanced API management features such as usage plans and API keys.

Use JWT authorizers or Cognito when you are ready to protect APIs with user authentication.
