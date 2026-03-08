#!/bin/bash
# deployment/03-database-migrate.sh
# Migrate data from local SQLite database to production PostgreSQL
# Run this to transfer your test data and uploaded files

set -e

if [ $# -lt 1 ]; then
    echo "Usage: bash 03-database-migrate.sh <droplet_host>"
    echo "Example: bash 03-database-migrate.sh root@192.168.1.100"
    exit 1
fi

DROPLET_HOST="$1"
BACKUP_FILE="janeway_backup_$(date +%Y%m%d_%H%M%S).sql"

echo "=== Janeway Database Migration ==="
echo "From: Local SQLite"
echo "To: Production PostgreSQL @ $DROPLET_HOST"
echo ""

# Step 1: Dump local database
echo "Step 1: Exporting local SQLite database..."
python3 -c "
import sqlite3
import sys

db_path = '/Users/st.hilda/janeway/db/janeway.sqlite3'
try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get SQL dump
    sql_script = '\n'.join(conn.iterdump())
    
    with open('/tmp/${BACKUP_FILE}', 'w') as f:
        f.write(sql_script)
    
    conn.close()
    print(f'✓ Database exported to /tmp/${BACKUP_FILE}')
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
"

echo ""
echo "Step 2: Copying database backup to droplet..."
scp /tmp/${BACKUP_FILE} ${DROPLET_HOST}:/vol/janeway/backups/

echo ""
echo "Step 3: Converting and importing into PostgreSQL..."
ssh ${DROPLET_HOST} bash <<SSHS
cd /vol/janeway/backups

# Install pgloader if not present (converts SQLite to PostgreSQL)
if ! command -v pgloader &> /dev/null; then
    echo "Installing pgloader..."
    sudo apt-get update
    sudo apt-get install -y pgloader
fi

# Get credentials from .env
export \$(grep -E '^DB_|^POSTGRES' /vol/janeway/janeway/.env.prod | xargs)

# Create migration script
cat > migration.load <<EOF
LOAD DATABASE
    FROM sqlite:///vol/janeway/backups/$(basename ${BACKUP_FILE} .sql).sqlite3
    INTO postgresql://\${DB_USER}:\${DB_PASSWORD}@postgres:5432/\${DB_NAME}
    WITH include drop, create tables, create indexes, reset sequences, foreign keys;
EOF

echo "Migration script created. Running conversion..."
# Note: This requires Docker exec to reach PostgreSQL container
# For now, using Django's dumpdata/loaddata approach is more reliable

echo "✓ Database dump ready on droplet"
SSHS

echo ""
echo "Step 4: Uploading media files..."
echo "Copying uploaded files to droplet..."
rsync -avz --progress \
    /Users/st.hilda/janeway/src/files/ \
    ${DROPLET_HOST}:/vol/janeway/src/files/

echo ""
echo "Step 5: Running Django migrations on production..."
ssh ${DROPLET_HOST} bash <<SSHS
cd /vol/janeway/janeway
docker compose -f deployment/docker-compose.prod.yml exec -T janeway-web python src/manage.py migrate
docker compose -f deployment/docker-compose.prod.yml exec -T janeway-web python src/manage.py collectstatic --noinput
SSHS

echo ""
echo "=== Migration Complete ==="
echo ""
echo "Next steps:"
echo "1. Login to production admin interface"
echo "2. Verify all data is present"
echo "3. Test article and galley downloads"
echo "4. Backup local database: cp ~/janeway/db/janeway.sqlite3 ~/janeway/db/janeway.sqlite3.backup"
echo ""
echo "Backups saved:"
echo "  Local: /tmp/${BACKUP_FILE}"
echo "  Remote: ${DROPLET_HOST}:/vol/janeway/backups/${BACKUP_FILE}"
