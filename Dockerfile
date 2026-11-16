# syntax=docker/dockerfile:1
# Community packaging for the official LightCraft WebAssembly application.
# The WebAssembly build runs ONCE in GitHub Actions; this runtime stage only serves its output.
FROM nginx:1.28-alpine

ARG LIGHTCRAFT_COMMIT=unknown
ARG LIGHTCRAFT_VERSION=unknown

LABEL org.opencontainers.image.title="LightCraft Web" \
      org.opencontainers.image.description="Community-maintained browser build of LightCraft" \
      org.opencontainers.image.source="https://github.com/storytold/lightcraft" \
      org.opencontainers.image.url="https://github.com/MikaPST/lightcraft-web" \
      org.opencontainers.image.version="${LIGHTCRAFT_VERSION}" \
      org.opencontainers.image.revision="${LIGHTCRAFT_COMMIT}"

# Own the complete NGINX configuration; it is maintained in this repository.
COPY nginx.conf /etc/nginx/nginx.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/licenses/

# All served files are readable by nginx; the unprivileged user needs no write access.
USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
