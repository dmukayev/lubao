FROM postgres:16-alpine
# mc — копия бакетов MinIO; busybox crond не нужен: скрипт сам ждёт своего часа.
RUN apk add --no-cache curl bash tzdata \
 && curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc \
 && chmod +x /usr/local/bin/mc
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh
ENTRYPOINT ["/usr/local/bin/backup.sh", "loop"]
