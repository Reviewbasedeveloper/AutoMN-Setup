#!/bin/bash
# ReviewBaseCoin Masternode Setup Script V1 for Ubuntu 16.04 LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash reviewbase_coin.autoinstall.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=11915
RPC=11914

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'reviewbase_coind' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop reviewbase_coind${NC}"
        reviewbase_coin-cli stop
        sleep 30
        if pgrep -x 'reviewbase_coind' > /dev/null; then
            echo -e "${RED}reviewbase_coind daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 reviewbase_coind
            sleep 30
            if pgrep -x 'reviewbase_coind' > /dev/null; then
                echo -e "${RED}Can't stop reviewbase_coind! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}
#Function detect_ubuntu

 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
else
   echo -e "${RED}You are not running Ubuntu 16.04, Installation is cancelled.${NC}"
   exit 1

fi

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN} ------- ReviewBaseCoin MASTERNODE INSTALLER v1.0.0--------+
 |                                                  |
 |                                                  |::
 |       The installation will install and run      |::
 |        the masternode under a user reviewbase_coin.         |::
 |                                                  |::
 |        This version of installer will setup      |::
 |           fail2ban and ufw for your safety.      |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Packages already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libevent-dev -y
sudo apt-get install unzip
sudo apt install unzip
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get -y install libminiupnpc-dev
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5 -y
   fi

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi
 
#Installing Daemon
cd ~
rm -rf /usr/local/bin/reviewbase_coin*
wget https://github.com/Reviewbasedeveloper/RVIEW-Coin/releases/download/v1.0/RVIEW-1.0-daemon-ubuntu_16.04.tar.gz
tar -xzvf RVIEW-1.0-daemon-ubuntu_16.04.tar.gz
sudo chmod -R 755 reviewbase_coin-cli
sudo chmod -R 755 reviewbase_coind
cp -p -r reviewbase_coind /usr/local/bin
cp -p -r reviewbase_coin-cli /usr/local/bin

 reviewbase_coin-cli stop
 sleep 5
 #Create datadir
 if [ ! -f ~/.reviewbase_coin/reviewbase_coin.conf ]; then 
 	sudo mkdir ~/.reviewbase_coin
 fi

cd ~
clear
echo -e "${YELLOW}Creating reviewbase_coin.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.reviewbase_coin/reviewbase_coin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.reviewbase_coin/reviewbase_coin.conf

    #Starting daemon first time just to generate masternode private key
    reviewbase_coind -daemon
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(reviewbase_coin-cli createmasternodekey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi
    
    #Stopping daemon to create reviewbase_coin.conf
    reviewbase_coin-cli stop
    sleep 5
cd ~/.reviewbase_coin/ && rm -rf blocks chainstate sporks zerocoin
cd ~/.reviewbase_coin/ && wget https://github.com/Reviewbasedeveloper/RVIEW-Coin/releases/download/v1.0/bootstrap.zip
cd ~/.reviewbase_coin/ && unzip bootstrap.zip	
# Create reviewbase_coin.conf
cat <<EOF > ~/.reviewbase_coin/reviewbase_coin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip
masternodeaddr=$publicip
masternodeprivkey=$genkey
addnode=157.245.164.19
addnode=167.71.117.89
addnode=167.71.117.112
addnode=167.71.125.170
addnode=167.71.115.18
addnode=167.71.126.74
addnode=157.245.173.128
addnode=217.163.11.156
addnode=178.128.255.160
addnode=165.22.156.181
addnode=45.76.128.72
addnode=165.22.156.181
addnode=209.250.231.178
addnode=165.22.156.181
addnode=157.230.147.48
addnode=68.183.171.230
addnode=165.22.156.181
addnode=178.128.255.160
addnode=157.230.139.231
addnode=68.183.171.230
addnode=165.22.156.181
addnode=167.71.115.18
addnode=157.230.139.231
addnode=178.128.255.160
addnode=157.230.147.48
addnode=165.22.156.181
addnode=157.230.139.231
addnode=68.183.171.230
addnode=167.71.125.170
addnode=157.230.139.231
addnode=157.230.139.231
addnode=167.71.126.74
addnode=157.230.139.231
addnode=178.128.255.160
addnode=165.22.156.181
addnode=157.230.139.231
addnode=165.22.156.181
addnode=157.230.139.231
addnode=178.128.255.160
addnode=165.22.156.181
addnode=165.22.156.181
addnode=167.71.117.112
addnode=157.230.147.48
addnode=165.22.156.181
addnode=167.71.117.89
addnode=178.128.255.160
addnode=165.22.156.181
addnode=178.128.255.160
addnode=178.128.255.160
addnode=178.128.255.160
 
EOF
    reviewbase_coind -daemon
#Finally, starting daemon with new reviewbase_coin.conf
printf '#!/bin/bash\nif [ ! -f "~/.reviewbase_coin/reviewbase_coin.pid" ]; then /usr/local/bin/reviewbase_coind -daemon ; fi' > /root/reviewbase_coinauto.sh
chmod -R 755 reviewbase_coinauto.sh
#Setting auto start cron job for reviewbase_coin
if ! crontab -l | grep "reviewbase_coinauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/reviewbase_coinauto.sh")| crontab -
fi

echo -e "========================================================================
${GREEN}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${GREEN}reviewbase_coin_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}reviewbase_coin_mn1${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from getmasternodeoutputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the reviewbase_coin network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in reviewbase_coin.conf:
${GREEN}cat ~/.reviewbase_coin/reviewbase_coin.conf${NC}
Here is your reviewbase_coin.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}reviewbase_coin_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.reviewbase_coin/reviewbase_coin.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit reviewbase_coin.conf, first stop the reviewbase_coind daemon,
then edit the reviewbase_coin.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the reviewbase_coind daemon back up:
to stop:              ${GREEN}reviewbase_coin-cli stop${NC}
to start:             ${GREEN}reviewbase_coind${NC}
to edit:              ${GREEN}nano ~/.reviewbase_coin/reviewbase_coin.conf${NC}
to check mn status:   ${GREEN}reviewbase_coin-cli getmasternodestatus${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================
"