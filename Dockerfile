# Stage 1: Build Frontend
FROM node:20 AS web-builder
WORKDIR /app
RUN npm install -g pnpm
COPY OpenList-Frontend-main/package.json OpenList-Frontend-main/pnpm-lock.yaml ./
RUN pnpm install --no-frozen-lockfile
COPY OpenList-Frontend-main/ ./
RUN pnpm build

# Stage 2: Build Backend
FROM golang:1.25-alpine AS go-builder
WORKDIR /app
RUN apk add --no-cache git bash build-base
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Copy frontend dist to public/dist for embedding
COPY --from=web-builder /app/dist ./public/dist

# Build logic similar to build.sh but optimized for Docker
RUN builtAt="$(date +'%F %T %z')" && \
    gitAuthor="OpenList Contributors" && \
    gitCommit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") && \
    version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v4.0.0") && \
    CGO_ENABLED=1 go build -o openlist \
    -ldflags="-w -s \
    -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.BuiltAt=$builtAt' \
    -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitAuthor=$gitAuthor' \
    -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitCommit=$gitCommit' \
    -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.Version=$version' \
    -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.WebVersion=$version'" \
    -tags=jsoniter .

# Stage 3: Final Runtime
FROM alpine:latest
RUN apk add --no-cache ca-certificates tzdata bash
WORKDIR /opt/openlist
COPY --from=go-builder /app/openlist ./
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables
ENV PUID=1000 PGID=1000 UMASK=022
VOLUME /opt/openlist/data
EXPOSE 5244 5245

ENTRYPOINT ["/entrypoint.sh"]
