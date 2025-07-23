FROM python:3.9.10-alpine3.15

ARG CREATED
ARG VERSION
ARG VCS_REF

LABEL \
    org.opencontainers.image.title="guestbook" \
    org.opencontainers.image.description="Guestbook is a simple cloud-native web application which allows visitors to leave a public comment without creating a user account." \
    org.opencontainers.image.created=${CREATED} \
    org.opencontainers.image.source="https://github.com/ReyRedd/guestbook" \
    org.opencontainers.image.url="https://hub.docker.com/repository/docker/reyredd/guestbook/tags" \
    org.opencontainers.image.version=${VERSION} \
    org.opencontainers.image.revision=${VCS_REF} \
    org.opencontainers.image.authors="reyredd" \
    org.opencontainers.image.vendor="ReyRedd" \
    org.opencontainers.image.base.digest="sha256:9d771c4b7c194a869ce238151f0ee2333a61d4126579d5fa37b64fe2fa9624cf" \
    org.opencontainers.image.base.name="docker.io/library/python:3.9.10-alpine3.15"

RUN addgroup -S guestbook && adduser -S guestbook -G guestbook

USER guestbook

WORKDIR /app

# Details: https://pythonspeed.com/articles/docker-caching-model/
COPY requirements/ ./requirements
COPY requirements.txt entrypoint.sh ./

USER root

RUN python3 -m pip install -r requirements.txt --no-cache-dir

RUN \
    apk update && \
    apk add postgresql-libs && \
    apk add --virtual .build-deps gcc musl-dev postgresql-dev && \
    apk --purge del .build-deps

USER guestbook

COPY --chown=guestbook:guestbook . .

RUN chmod +x entrypoint.sh

ENV FLASK_APP=main.py

EXPOSE 5000

ENTRYPOINT [ "./entrypoint.sh" ]
