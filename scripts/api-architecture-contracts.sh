#!/bin/bash
# Outputs frontend awareness rules based on project type.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

case "$TYPE" in
  frontend)
    cat << 'EOF'
## Role: Frontend project

This project IS the frontend. Frontend awareness rules apply inward:
- Follow the API contract defined by the backend — do not assume response shapes
- Do not hardcode API URLs — use environment variables or config
- Validate API responses before rendering — handle null/undefined fields defensively
- Do not expose sensitive data (tokens, keys) in client-side code or logs
- Keep UI state in sync with server state — invalidate caches on mutations

### Component contract rules
- Do not change a component's required props without updating all call sites
- Do not rename exported components without updating all imports
- Keep event handler signatures consistent — consumers depend on them
EOF
    ;;

  backend)
    cat << 'EOF'
## Role: Backend project

This project IS the backend. Frontend awareness rules apply outward:
- Never remove or rename a response field without coordinating with consumers
- Never change the type of an existing field (string → number, object → array)
- Never change an endpoint route or HTTP method without a deprecation path
- Keep error response shapes consistent across all endpoints
- Keep HTTP status codes consistent — do not change 200 → 201 silently
- Keep date formats as ISO 8601 UTC throughout
- Keep pagination parameter names stable (page/limit or offset/size — pick one)
- Adding new optional fields to a response is non-breaking — fine to do
- Adding new endpoints is non-breaking — fine to do

### Flag to human when
- A DTO field is removed or renamed
- An endpoint route or method changes
- Auth is added or removed from an existing endpoint
- An error code or message format changes
EOF
    ;;

  fullstack)
    cat << 'EOF'
## Role: Fullstack project

This project contains both frontend and backend. Verify which layer is being changed:

### If changing the backend (API layer)
- Do not remove or rename response fields the frontend consumes
- Grep the frontend code for the field/endpoint before removing it
- Keep HTTP status codes and error shapes consistent
- Adding new optional fields or endpoints is safe

### If changing the frontend (UI layer)
- Follow the API contract — do not assume response shapes changed
- Do not hardcode API URLs — use environment config
- Do not expose tokens or keys in client-side code

### Cross-cutting
- Keep date formats as ISO 8601 UTC
- Keep pagination contracts stable
EOF
    ;;

  monolith)
    cat << 'EOF'
## Role: Monolith (multiple stacks, single repo)

This project contains backend and frontend code in different stacks within the same repository.

### If changing the backend (PHP / server-side)
- Never remove or rename a response field without checking frontend usage
- Grep the frontend JS/CSS/template files for the field or endpoint before removing it
- Keep error response shapes and HTTP status codes consistent
- Server-rendered views (Blade, Twig, ERB) and API endpoints may share controllers — check both consumers
- Adding new optional fields or endpoints is safe

### If changing the frontend (JS / assets / templates)
- Follow the API contract — do not assume response shapes changed
- Do not hardcode API URLs — use routes/config provided by the backend
- Do not expose tokens, keys, or CSRF tokens in client-side JS (except in meta tags where the framework provides them)
- jQuery AJAX calls: check the response shape matches what the backend returns

### Cross-cutting
- Keep date formats consistent between server-rendered views and API responses
- Keep pagination contracts stable
- Server-rendered HTML and API JSON may coexist on the same controller — be aware of both
- CSRF protection: ensure forms and AJAX requests include the CSRF token

### Flag to human when
- A backend route or response field changes that frontend JS depends on
- A Blade/Twig variable is removed that templates reference
- Auth middleware is added or removed from an existing route
- An endpoint switches between HTML and JSON response
EOF
    ;;

  *)
    cat << 'EOF'
Project type not configured. Run `/dev-workflow:init` to set frontend/backend/fullstack/monolith.

Generic frontend awareness rules:
- Do not break existing API contracts without coordinating with consumers
- Do not expose sensitive data in client-side code
- Keep response shapes and HTTP status codes consistent
EOF
    ;;
esac
