# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS build
WORKDIR /src
# go.sum may not exist yet on first build; the glob keeps COPY from failing.
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates wget \
 && adduser -D -u 10001 app
USER app
COPY --from=build /out/server /usr/local/bin/server
EXPOSE 8080
ENTRYPOINT ["server"]
