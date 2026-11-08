# Shiprr compatibility assessment

## Status: not deployable as a complete 3x-ui service on Shiprr today

The current Shiprr documentation states that:

- source builds are supported for listed runtimes and shell scripts;
- custom Dockerfiles and prebuilt Docker image deployments are not supported;
- app replica filesystems are ephemeral and persistent disks are not provided.

References:
- https://shiprr.app/docs/supported-apps
- https://shiprr.app/docs/limits
- https://shiprr.app/docs/network
- https://shiprr.app/docs/troubleshooting

This project depends on more than a single HTTP web process:

1. 3x-ui and its Xray core run as a long-lived service.
2. The panel database and configuration live under `/etc/x-ui` and need
   durable storage across redeploys/restarts.
3. VLESS/WebSocket can be proxied over HTTP if WebSocket upgrades are passed
   through, but regular TCP and UDP inbounds require network exposure beyond
   an ordinary managed HTTP app endpoint.
4. The current package starts both 3x-ui and Nginx; a source build alone does
   not provide the same OS packages, process supervision, or network model
   as the Dockerfile.

## What would be required for full support

Shiprr would need to provide (or confirm support for):

- a durable volume or external persistent database/storage for 3x-ui state;
- long-running multi-process services or a supported process supervisor;
- WebSocket upgrade forwarding for the HTTP-based inbound;
- direct TCP and UDP port exposure if non-WebSocket inbounds are required.

Until those capabilities are confirmed, do not label this repository as
Shiprr-compatible. Deploying a temporary panel with ephemeral SQLite state
could lose users and inbound configuration after a replacement.
