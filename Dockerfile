FROM node:22-alpine AS dependencies

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force


FROM gcr.io/distroless/nodejs22-debian12:nonroot

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --chown=nonroot:nonroot package.json app.js ./

EXPOSE 3000

USER nonroot

CMD ["app.js"]