sudo apt update && sudo apt upgrade
sudo apt install software-properties-common
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install lib32gcc-s1 steamcmd

sudo useradd -m steam
sudo su steam
cd /home/steam
/usr/games/steamcmd +login anonymous +app_update 2394010 validate +quit
./PalServer.sh