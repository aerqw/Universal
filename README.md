# 3x-ui Upgrade — Portable Docker deployment

This repository packages upstream [3x-ui](https://github.com/MHSanaei/3x-ui)
behind Nginx. The original Railway-specific fixed public port has been
replaced with a configurable `PORT` variable.

## Important platform compatibility note

This project is a multi-process service (3x-ui/Xray + Nginx) and needs durable
storage for `/etc/x-ui`. Its WebSocket inbound can be proxied through an HTTP
entry point, but ordinary TCP/UDP inbounds need direct network ports.

**Shiprr currently builds source repositories using its managed runtime. It
does not support custom Dockerfiles or prebuilt images, and its app filesystem
is ephemeral with no persistent disk.** Therefore this Docker-based package
cannot be deployed as-is on Shiprr, and a source-only wrapper does not solve
the missing durable storage / inbound-network requirements. See
[SHIPRR-COMPATIBILITY.md](SHIPRR-COMPATIBILITY.md).

## Docker / Dockerfile-based platforms

Build and run:

```bash
docker build -t 3x-ui-upgrade .
docker run -d \
  --name 3x-ui-upgrade \
  -p 3000:3000 \
  -v xui-data:/etc/x-ui \
  -e PORT=3000 \
  3x-ui-upgrade
```

For a PaaS that injects `PORT`, no fixed public port is assumed by the
container. The process listens on `0.0.0.0:$PORT` through Nginx.

### Environment variables

| Variable | Default | Purpose |
|---|---:|---|
| `PORT` | `3000` | Public HTTP/WebSocket port supplied by the platform |
| `PANEL_PORT` | `2053` | Internal 3x-ui panel port |
| `SUB_PORT` | `2096` | Internal subscription port |
| `INBOUND_PORT` | `8080` | Internal VLESS/WebSocket inbound port |
| `WEB_BASE_PATH` | `/managepanel/` | Panel URL base path |
| `TZ` | `Asia/Tehran` | Container timezone |

### Persistent data

Mount a persistent volume at `/etc/x-ui`. Without it, the SQLite database
and panel settings may be lost when the container is replaced.

### Panel URL

```text
https://YOUR-DOMAIN/managepanel/
```

Change the default panel credentials immediately after first login.

### WebSocket inbound

Create a VLESS inbound using:
- Listen port: `8080` (or the value of `INBOUND_PORT`)
- Network: `ws`
- Security: `none` behind the platform's HTTPS edge
- Path: choose a path and use the same path in the client configuration

The public HTTP/WebSocket entry point is the platform's `PORT`. This does not
make arbitrary TCP/UDP inbounds available through platforms that only expose
HTTP traffic.

## Railway

The same Dockerfile can be deployed from GitHub. Attach a persistent volume
at `/etc/x-ui`. Railway's injected `PORT` is used automatically.

## Other Docker platforms

Use the Dockerfile and configure:
- a public HTTP port mapped to container `PORT`
- a persistent volume at `/etc/x-ui`
- WebSocket support if you intend to route a VLESS/WS inbound through the
  public HTTP port

Platforms differ in their TCP/UDP ingress, volume, and process-management
features. A successful image build alone does not guarantee that all 3x-ui
inbound protocols will work.
