# get a simple builder image
FROM node:22-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
  apt-get install git git-crypt jq -qq < /dev/null > /dev/null && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /usr/local/bin/yarn /usr/local/bin/yarnpkg && \
  corepack enable && \
  corepack install --global pnpm@latest

WORKDIR /app
COPY . /app
RUN pnpm install && pnpm build:supertic

# switch to a distroless image
FROM nginxinc/nginx-unprivileged:stable AS base

COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN echo "charset utf-8;" > /etc/nginx/conf.d/charset.conf
RUN mkdir -p /tmp/root/var/cache/nginx && \
  cp -a --parents /usr/lib/nginx \
  /usr/share/nginx \
  /var/log/nginx \
  /etc/nginx \
  /usr/sbin/nginx \
  /usr/sbin/nginx-debug \
  /lib/*/ld-* \
  /lib/*/libpcre* \
  /lib/*/libz* \
  /lib/*/libc* \
  /lib/*/libdl* \
  /lib/*/libpthread* \
  /usr/lib/*/libssl* \
  /usr/lib/*/libcrypto* \
  /usr/lib/*/libpcre* \
  /tmp/root

FROM gcr.io/distroless/base:latest
USER 1000

EXPOSE 8081

COPY --from=base /tmp/root /
CMD ["nginx", "-g", "daemon off;"]

COPY --from=builder /app/dist/apps/supertic /usr/share/nginx/html
