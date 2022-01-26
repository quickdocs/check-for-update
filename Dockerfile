FROM alpine:3.15

RUN set -x; \
  apk add --update bash jq curl

COPY check-for-update.sh /usr/bin

CMD ["check-for-update.sh"]
