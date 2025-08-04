#!/bin/bash

# Warna untuk tampilan
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== ANALISIS ANGKA PSEUDO TOGEL ===${NC}"

# Input dari user
read -p "Berapa kali simulasi (misal 1000): " TOTAL_DRAWS
read -p "Berapa digit per angka (4 atau 6): " DIGIT

declare -A freq

# Inisialisasi frekuensi
for i in {0..9}; do
    freq[$i]=0
done

echo -e "\n${YELLOW}Simulasi $TOTAL_DRAWS kali, $DIGIT digit per angka...${NC}"
echo "==========================================="

# Generate angka dan hitung frekuensi
for (( i=1; i<=TOTAL_DRAWS; i++ )); do
    for (( j=1; j<=DIGIT; j++ )); do
        digit=$((RANDOM % 10))
        freq[$digit]=$((freq[$digit]+1))
    done
done

# Tampilkan hasil dalam bentuk tabel
echo -e "\n${CYAN}=== FREKUENSI ANGKA (0-9) ===${NC}"
printf "%-10s | %-10s\n" "Angka" "Frekuensi"
echo "-----------------------------"
for i in {0..9}; do
    printf "%-10s | %-10s\n" "$i" "${freq[$i]}"
done

# Cari angka paling sering & paling jarang
max_digit=0
max_freq=${freq[0]}
min_digit=0
min_freq=${freq[0]}

for i in {1..9}; do
    if [ ${freq[$i]} -gt $max_freq ]; then
        max_freq=${freq[$i]}
        max_digit=$i
    fi
    if [ ${freq[$i]} -lt $min_freq ]; then
        min_freq=${freq[$i]}
        min_digit=$i
    fi
done

echo -e "\n${GREEN}Angka paling sering muncul:${NC} $max_digit (${max_freq} kali)"
echo -e "${RED}Angka paling jarang muncul:${NC} $min_digit (${min_freq} kali)"
echo ""
