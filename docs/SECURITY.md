# Security Model

NOVA uses a server-side credential boundary: Gemini and Supabase credentials belong only in n8n's credential store. The frontend stores the configured Chat URL, a browser session identifier, and visible conversation history in local storage; it contains no provider secret.

## Included controls

- Unicode normalization and null-byte removal
- Empty-message and 4,000-character input validation
- Sanitized, length-limited session identifiers
- Pattern-based risk flags for secret exfiltration, instruction override, encoded payloads, and destructive requests
- Session-based application rate checks
- Explicit deterministic routing
- Supabase Row Level Security
- Restricted browser access to database tables
- Durable logging of route, model, metadata, timestamps, and risk flags
- Server-side service-role access
- Exact-origin CORS configuration through the n8n Chat Trigger

Risk flags support audit and policy-aware handling; they are not a complete content-security system.

## Deployment hardening

Before exposing NOVA publicly, add controls appropriate to the deployment:

- Reverse proxy and TLS
- Web Application Firewall
- Infrastructure-level IP and user rate limits
- Authentication and authorization where appropriate
- Narrow, explicit CORS origins
- Centralized monitoring and alerting
- Database backups and tested restoration
- Credential rotation and least-privilege access
- Data-retention rules and a privacy policy
- Dependency, workflow, and configuration reviews

Application-level rate limiting does not replace infrastructure protection. Row Level Security and server-side credentials reduce exposure but do not make a deployment automatically compliant or suitable for regulated data.

## Secret-handling rules

Never commit:

- Gemini API keys
- Supabase service-role or anon keys
- n8n credential exports
- `.env` files
- execution payloads containing customer information
- screenshots that reveal tokens, URLs with secrets, or personal data

If a credential is accidentally committed, revoke it immediately, remove it from Git history, and rotate all dependent secrets.

## Trust boundary

NOVA supplies architectural, technical, and commercial guidance. It does not automatically perform destructive actions. Any recommendation affecting production systems, access controls, billing, or customer data should receive human review and environment-specific testing.

