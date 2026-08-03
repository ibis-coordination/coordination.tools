#!/bin/sh
# Nightly pg_dump to DigitalOcean Spaces. Run by the db-backup Kamal
# accessory (see config/deploy.yml), which provides:
#   DB_HOST, POSTGRES_USER, POSTGRES_DB, PGPASSWORD   - database connection
#   SPACES_BUCKET, SPACES_ENDPOINT                    - Spaces target
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY         - Spaces credentials
#   BACKUP_KEEP                                       - dumps to retain
set -eu

apk add --no-cache aws-cli

while true; do
  stamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
  file="${POSTGRES_DB}_${stamp}.sql.gz"

  echo "Dumping ${POSTGRES_DB} to ${file}"
  pg_dump -h "$DB_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "/tmp/${file}"
  aws s3 cp "/tmp/${file}" "s3://${SPACES_BUCKET}/postgres/${file}" --endpoint-url "$SPACES_ENDPOINT"
  rm -f "/tmp/${file}"

  echo "Pruning dumps beyond the newest ${BACKUP_KEEP}"
  aws s3 ls "s3://${SPACES_BUCKET}/postgres/" --endpoint-url "$SPACES_ENDPOINT" \
    | awk '{print $NF}' | sort -r | tail -n "+$((BACKUP_KEEP + 1))" \
    | while read -r old; do
        [ -n "$old" ] && aws s3 rm "s3://${SPACES_BUCKET}/postgres/${old}" --endpoint-url "$SPACES_ENDPOINT"
      done

  echo "Backup complete; sleeping 24h"
  sleep 86400
done
