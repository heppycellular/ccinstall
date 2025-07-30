#!/bin/bash

# --- URL File Pre-compiled ---
CCMINER_BIN_URL="https://github.com/heppycellular/ccinstall/raw/main/ccminer"
CONFIG_JSON_URL="https://raw.githubusercontent.com/Darktron/pre-compiled/generic/config.json" # Ini akan ditimpa
START_SH_URL="https://raw.githubusercontent.com/Darktron/pre-compiled/generic/start.sh" # Ini akan ditimpa

echo "--- Script Download & Setup CCminer Verus Coin (Monitor & Background) ---"
echo "Script ini akan menyiapkan miner dan membiarkannya berjalan di latar belakang setelah terkoneksi."
echo ""

# --- Minta Input dari Pengguna ---
read -p "Masukkan ALAMAT WALLET Verus Coin Anda (contoh: R*****.Q*****.A*****): " WALLET_ADDRESS
read -p "Masukkan NAMA WORKER Anda (opsional, tekan Enter untuk 'default_miner'): " WORKER_NAME
WORKER_NAME=${WORKER_NAME:-default_miner}

# Nilai threads akan tetap 8, tidak dideteksi secara otomatis
DEFAULT_THREADS=8

echo ""
echo "Detail Penambangan Anda:"
echo "Alamat Wallet : $WALLET_ADDRESS"
echo "Nama Worker   : $WORKER_NAME"
echo "Thread CPU    : $DEFAULT_THREADS (nilai tetap sesuai konfigurasi)"
echo ""

read -p "Tekan Enter untuk melanjutkan dengan detail di atas, atau Ctrl+C untuk membatalkan..."

---

### 1. Persiapan Direktori

echo "1. Membuat dan masuk ke direktori 'ccminer'..."
mkdir -p ~/ccminer
cd ~/ccminer
if [ $? -ne 0 ]; then
    echo "Gagal membuat atau masuk ke direktori 'ccminer'. Periksa izin."
    exit 1
fi
echo "Direktori 'ccminer' siap."

---

### 2. Mengunduh File

echo "2. Mengunduh binary ccminer, config.json (sementara), dan start.sh (sementara)..."
wget -q --show-progress ${CCMINER_BIN_URL}
wget -q --show-progress ${CONFIG_JSON_URL}
wget -q --show-progress ${START_SH_URL} # Ini akan segera ditimpa

if [ $? -ne 0 ]; then
    echo "Gagal mengunduh file. Periksa koneksi internet atau URL repositori."
    exit 1
fi
echo "File berhasil diunduh."

---

### 3. Mengatur Izin Eksekusi

echo "3. Memberikan izin eksekusi pada ccminer dan start.sh..."
chmod +x ccminer start.sh
if [ $? -ne 0 ]; then
    echo "Gagal memberikan izin eksekusi."
    exit 1
fi
echo "Izin eksekusi diberikan."

---

### 4. Menulis Ulang File Konfigurasi (config.json)

echo "4. Menulis ulang config.json dengan detail mining Anda dan konfigurasi multi-pool..."
# Menggunakan 'EOF' tanpa kutip tunggal agar variabel shell bisa diekspansi
cat << EOF > config.json
{
    "pools":
        [{
            "name": "US-VIPOR",
            "url": "stratum+tcp://us.vipor.net:5040",
            "timeout": 180,
            "disabled": 0
        },
        {
            "name": "USSE-VIPOR",
            "url": "stratum+tcp://usse.vipor.net:5040",
            "timeout": 180,
            "disabled": 0
        },
        {
            "name": "NA-LUCKPOOL",
            "url": "stratum+tcp://na.luckpool.net:3960",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "AIH-LOW",
            "url": "stratum+tcp://verus.aninterestinghole.xyz:9998",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "WW-ZERGPOOL",
            "url": "stratum+tcp://verushash.mine.zergpool.com:3300",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "VPOOL-LOW",
            "url": "stratum+tcp://pool.verus.io:9998",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "US-CLOUDIKO",
            "url": "stratum+tcp://us.cloudiko.io:9999",
            "timeout": 180,
            "disabled": 1
        }],

    "user": "${WALLET_ADDRESS}.${WORKER_NAME}",
    "pass": "",
    "algo": "verus",
    "threads": ${DEFAULT_THREADS},
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOF
echo "config.json telah berhasil diatur dengan detail Anda."

---

### 5. Menulis Ulang Script Start Miner (start.sh) untuk Pemantauan Otomatis

echo "5. Menulis ulang start.sh untuk memantau koneksi dan berjalan di latar belakang..."
cat << 'EOF_START' > start.sh
#!/bin/bash

MINER_LOG="miner_output.log" # File log untuk output miner

echo "Memulai CCminer. Memantau koneksi..."
# Hapus log lama jika ada
rm -f "${MINER_LOG}"

# Jalankan ccminer dan simpan outputnya ke file log sementara
# Gunakan 'stdbuf -oL' untuk memastikan output ditulis ke log secara real-time
./ccminer 2>&1 | stdbuf -oL tee "${MINER_LOG}" &

MINER_PID=$! # Dapatkan PID dari ccminer yang baru saja dimulai

# Tunggu hingga string "accepted" muncul di log, atau sampai 30 detik
TIMEOUT=30
ELAPSED=0
SUCCESS=false

echo "Mencari string 'accepted' atau 'Mining on'"

while [ $ELAPSED -lt $TIMEOUT ]; do
    if grep -qE "accepted|Mining on" "${MINER_LOG}"; then
        echo "--------------------------------------------------------"
        echo "Miner TERKONEKSI dan mulai menambang! Output terakhir:"
        tail -n 10 "${MINER_LOG}" # Tampilkan beberapa baris terakhir
        echo "--------------------------------------------------------"
        SUCCESS=true
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ "$SUCCESS" = true ]; then
    echo "Miner sekarang berjalan di latar belakang. Outputnya dialihkan ke ${MINER_LOG}"
    echo "Anda bisa menutup terminal ini. Untuk melihat log real-time: tail -f ${MINER_LOG}"
    # Pastikan miner tetap berjalan di latar belakang
    # Tidak perlu kill dan nohup ulang karena sudah berjalan dengan & di atas
    # Cukup informasikan pengguna
else
    echo "--------------------------------------------------------"
    echo "Timeout! Miner TIDAK berhasil terkoneksi dalam ${TIMEOUT} detik."
    echo "Periksa log (${MINER_LOG}) untuk detail error."
    echo "--------------------------------------------------------"
fi
EOF_START
chmod +x start.sh
echo "Script start.sh telah diatur."

---

### 6. Menjalankan Miner Otomatis & Informasi Penting

echo "---"
echo "--- Setup Selesai! ---"
echo "Miner akan otomatis dijalankan sebentar lagi. Perhatikan outputnya."
echo ""

# --- Opsi Auto-Start (Untuk Termux di Android) ---
echo "Untuk membuat CCminer berjalan otomatis saat perangkat boot, Anda perlu menginstal **Termux:Boot**."
echo "1.  Instal **Termux:Boot** dari Google Play Store."
echo "2.  Setelah Termux:Boot terinstal, buat direktori di Termux untuk script auto-start:"
echo "    mkdir -p ~/.termux/boot"
echo "3.  Buat file script di dalamnya (misal, 'miner_boot.sh'):"
echo "    nano ~/.termux/boot/miner_boot.sh"
echo "4.  Masukkan perintah berikut ke dalam file 'miner_boot.sh':"
echo "    #!/data/data/com.termux/files/usr/bin/bash"
echo "    cd ~/ccminer"
echo "    # Untuk auto-start, jalankan start.sh di latar belakang tanpa pemantauan awal"
echo "    ./ccminer > /dev/null 2>&1 &" # Atau gunakan './start.sh > /dev/null 2>&1 &' jika start.sh tidak dipantau
echo "    # Penting: Jika start.sh sudah punya logika monitoring, langsung panggil start.sh saja."
echo "5.  Berikan izin eksekusi pada script tersebut:"
echo "    chmod +x ~/.termux/boot/miner_boot.sh"
echo ""
echo "Sekarang, setiap kali perangkat Anda boot, Termux:Boot akan menjalankan script ini secara otomatis."
echo ""
echo "--- Mengedit File Konfigurasi Bash (Opsional) ---"
echo "Jika Anda ingin mengedit file konfigurasi bash global Termux (bash.bashrc) secara manual,"
echo "Anda bisa membukanya dengan perintah:"
echo ""
echo "    nano /data/data/com.termux/files/usr/etc/bash.bashrc"
echo ""
echo "Berhati-hatilah saat mengedit file ini karena kesalahan dapat memengaruhi fungsi Termux Anda."
echo "Biasanya, Anda tidak perlu mengedit file ini untuk penambangan Verus Coin."
echo ""
echo "---"
echo "Catatan Penting Lainnya:"
echo "  - Pastikan binary ccminer dari Darktron kompatibel dengan arsitektur perangkat Anda."
echo "    Jika miner tidak berjalan atau crash, kemungkinan binary tidak cocok."
echo "  - Anda dapat mengedit file config.json secara manual di ~/ccminer/config.json"
echo "    jika Anda ingin mengubah pengaturan pool atau lainnya (termasuk jumlah thread)."
echo "  - Untuk melihat statistik penambangan, kunjungi website pool yang Anda gunakan dan masukkan alamat wallet Anda."
echo ""
echo "Selamat menambang Verus Coin!"

# --- Otomatis Menjalankan Miner (dengan pemantauan awal) ---
echo ""
echo "========================================"
echo "Memulai miner sekarang (Anda akan melihat output awal)..."
sleep 2 # Beri sedikit jeda sebelum menjalankan
cd ~/ccminer
./start.sh # Menjalankan start.sh yang baru dimodifikasi
echo "========================================"
echo ""
