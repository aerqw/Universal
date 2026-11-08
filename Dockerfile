FROM alpine:3.19

ARG XUI_VERSION=3.4.2

RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    socat \
    tzdata \
    sqlite \
    nginx \
    gettext \
    tar

ENV TZ=Asia/Tehran

RUN ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && echo "${TZ}" > /etc/timezone

# Download the upstream 3x-ui release. This image currently targets amd64,
# matching the original repository's release URL.
RUN curl -fL "https://github.com/mhsanaei/3x-ui/releases/download/v${XUI_VERSION}/x-ui-linux-amd64.tar.gz" \
      -o /tmp/x-ui.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /usr/local/ \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /etc/x-ui /var/log/x-ui

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3000
CMD ["/start.sh"]
