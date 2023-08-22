# ------------------------------------------------------------------- base ---

FROM node:18 as base

RUN mkdir -p /opt/app
WORKDIR /opt/app

ENV NODE_ENV development

ADD package*.json /opt/
RUN npm ci

ADD ./ ./

# -------------------------------------------------------------------- test ---

FROM base as test

RUN npm run lint

# -------------------------------------------------------------------- build ---

FROM test as build

RUN npm run build

# ----------------------------------------------------------------- package ---

FROM alpine:latest as package

COPY --from=build /opt/app/dist /opt/app/dist
COPY --from=build /opt/package-lock.json /opt/app/dist/

RUN apk add zip \
    && cd /opt/app/dist \
    && zip -r /tmp/package.zip .

