#!/bin/bash

# Load .env untuk dapat nama project
export $(grep -v '^#' .env | xargs)
PROJECT_NAME_FINAL=${PROJECT_NAME:-"frappe-ta-default"}

echo "🔍 Mencari aplikasi dari apps.json..."

# Gunakan python untuk memparse JSON (karena biasanya sudah ada di Linux)
APPS=$(python3 -c "import json; print(' '.join([f\"{a['url']}@{a['branch']}@{a['url'].split('/')[-1].replace('.git', '')}\" for a in json.load(open('apps.json'))]))")

# Tambahkan frappe dan erpnext secara manual karena mereka adalah core apps
# Format: URL@BRANCH@FOLDER_NAME
CORE_APPS="https://github.com/frappe/frappe.git@version-15@frappe"

for APP_DATA in $CORE_APPS $APPS; do
    IFS='@' read -r URL BRANCH FOLDER <<< "$APP_DATA"
    
    echo "🛠️  Memulihkan .git untuk: $FOLDER ($BRANCH)"
    
    # Perintah yang dijalankan di dalam container
    docker compose -p "$PROJECT_NAME_FINAL" exec -u frappe backend /bin/bash -c "
        cd apps/$FOLDER
        if [ ! -d .git ]; then
            git init -q
            git remote add origin $URL 2>/dev/null || git remote set-url origin $URL
            echo '   📥 Fetching data dari $URL...'
            git fetch origin $BRANCH --depth 1 -q
            git reset --hard FETCH_HEAD -q
            git checkout $BRANCH -q 2>/dev/null || git checkout -b $BRANCH FETCH_HEAD -q
            echo '   ✅ Metadata .git berhasil dipulihkan.'
        else
            echo '   ℹ️  Folder .git sudah ada, melewati...'
        fi
    "
done

echo "✨ Semua metadata Git berhasil disinkronisasi!"