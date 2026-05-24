# syntax=docker/dockerfile:1
# --- Build stage -------------------------------------------------------------
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

# --- Runtime stage -----------------------------------------------------------
FROM node:20-alpine AS runtime
WORKDIR /app

# Optional: add tzdata for proper timezone handling
RUN apk add --no-cache tzdata

ENV NODE_ENV=production
ENV TZ=Asia/Baku
# Nest listens on 3000 by default in our project
EXPOSE 3000

# Copy only what we need
COPY --from=builder /app/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

COPY --from=builder /app/dist ./dist

# (Optional) Drop root privileges
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app

CMD ["node", "dist/main.js"]
