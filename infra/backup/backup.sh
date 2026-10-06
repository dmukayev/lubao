#!/usr/bin/env bash
# Бэкапы (задача 043, п.6): `backup.sh once` — одна копия сейчас, `backup.sh loop` —
# каждый день в BACKUP_HOUR_UTC. Структура: /backups/<дата>/db.dump (pg_dump -Fc) и
# /backups/<дата>/minio/<бакет>/… ; старше BACKUP_KEEP_DAYS дней удаляются.
# BACKUP_REMOTE_CMD — команда выгрузки в ОТДЕЛЬНОЕ хранилище, получает путь папки
# дня первым аргументом (пример: "rclone copy" или "rsync -a --relative").
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

backup_once() {
  local day dir
  day="$(date -u +%Y-%m-%d)"
  dir="$BACKUP_DIR/$day"
  mkdir -p "$dir/minio"

  echo "[backup] $day: pg_dump"
  pg_dump -Fc --no-owner -f "$dir/db.dump.tmp"
  mv "$dir/db.dump.tmp" "$dir/db.dump"

  echo "[backup] $day: бакеты MinIO"
  mc alias set lubao "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
  for bucket in $(mc ls lubao | awk '{print $NF}' | tr -d '/'); do
    mc mirror --quiet --overwrite "lubao/$bucket" "$dir/minio/$bucket"
  done

  echo "[backup] $day: чистка копий старше $KEEP_DAYS дней"
  find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime "+$KEEP_DAYS" -exec rm -rf {} +

  if [[ -n "${BACKUP_REMOTE_CMD:-}" ]]; then
    echo "[backup] $day: выгрузка в отдельное хранилище"
    # shellcheck disable=SC2086
    $BACKUP_REMOTE_CMD "$dir"
  else
    echo "[backup] ВНИМАНИЕ: BACKUP_REMOTE_CMD не задан — копии лежат только на этом сервере"
  fi
  echo "[backup] $day: готово"
}

case "${1:-once}" in
  once) backup_once ;;
  loop)
    hour="${BACKUP_HOUR_UTC:-22}"
    while true; do
      now=$(date -u +%s)
      # busybox date понимает только «ГГГГ-ММ-ДД ЧЧ:ММ:СС».
      next=$(date -u -d "$(date -u +%Y-%m-%d) $(printf '%02d' "$hour"):00:00" +%s)
      [[ $next -le $now ]] && next=$((next + 86400))
      sleep $((next - now))
      backup_once || echo "[backup] ОШИБКА — повтор через сутки"
    done
    ;;
  *) echo "usage: backup.sh [once|loop]" >&2; exit 2 ;;
esac
