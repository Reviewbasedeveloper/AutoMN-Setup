# Guide for ReviewBase AutoMN Setup:


For **Ubuntu 16.04**
```
wget -q https://raw.githubusercontent.com/Reviewbasedeveloper/AutoMN-Setup/master/rview-mn.sh
sudo chmod +x rview-mn.sh
./rview-mn.sh
```
***

For **Ubuntu 18.04**
```
wget -q https://raw.githubusercontent.com/Reviewbasedeveloper/AutoMN-Setup/master/rview-mn-ubuntu_1804.sh
sudo chmod +x rview-mn-ubuntu_1804.sh
./rview-mn-ubuntu_1804.sh
```
***

Do you want me to generate a masternode private key for you?[y/n]

- If you don't want to generate a masternode private key press **n**.

  > Next ask for Private key:
  
  > Enter your private key: Paste Your Masternode Private Key
  
  > Confirm your private key: Again Paste Your Masternode Private Key for confirmation

**OR**

- If you want to generate a masternode private key press  **y**.

 Enter VPS Public IP Address: Paste your VPS Address

 Wait till Node is fully Synced with blockchain.

`reviewbase_coin-cli getinfo`

When Node is Fully Synced enter the command below to check the masternode status.

`reviewbase_coin-cli getmasternodestatus`

You will get Masternode Successfully Started

