```bash
pkg update && pkg upgrade -y
yes | pkg install libjansson wget nano -y
wget https://raw.githubusercontent.com/heppycellular/ccinstall/master/installer.sh
chmod +x installer.sh
./installer.sh
