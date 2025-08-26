FROM golang:1.24-alpine3.21 AS builder

RUN mkdir /app
ADD . /app
WORKDIR /app

RUN CGO_ENABLED=0 GOOS=linux go build -o seonaut cmd/server/main.go

FROM node:18-alpine3.18 AS front
WORKDIR /home/node
COPY --from=builder /app ./app/
RUN npm install --save-exact esbuild && ./node_modules/esbuild/bin/esbuild ./app/web/css/style.css \
	--bundle \
	--minify \
	--outdir=./app/web/static \
	--public-path=/resources \
	--loader:.woff=file \
	--loader:.woff2=file

FROM alpine:latest AS production
COPY --from=front /home/node/app /app/

ENV WAIT_VERSION 2.9.0
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /bin/wait
RUN chmod +x /bin/wait

ENV WAIT_HOSTS=db:3306 \
    WAIT_TIMEOUT=300 \
    WAIT_SLEEP_INTERVAL=30 \
    WAIT_HOST_CONNECT_TIMEOUT=30

WORKDIR /app
EXPOSE 9000

LABEL org.opencontainers.image.title="SEOnaut" \
      org.opencontainers.image.description="Technical SEO crawler and analyzer" \
      org.opencontainers.image.source="https://github.com/stjudewashere/seonaut" \
      org.opencontainers.image.url="https://seonaut.org" \
      org.opencontainers.image.vendor="SEOnaut" \
      org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["sh","-c","/bin/wait && /app/seonaut"]
