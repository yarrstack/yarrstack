# github.com/yarrstack/yarrstack

# 1. install dependencies
source .env
sudo apt update
sudo apt install -y curl jq wireguard resolvconf ufw nfs-common

# 2. disable ipv6 routing for ufw
echo "IPV6=no" >> /etc/default/ufw

# 3. configure wireguard service, this example uses mullvad vpn
curl -LO https://mullvad.net/media/files/mullvad-wg.sh && chmod +x ./mullvad-wg.sh && ./mullvad-wg.sh && rm ./mullvad-wg.sh
sudo systemctl enable wg-quick@$WG_LINK.service
sudo systemctl start wg-quick@WG_LINK.service

# 4. configure the firewall
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default deny outgoing

sudo ufw allow $WG_PORT/udp                                      # allow wireguard udp comms
sudo ufw allow out on $WG_LINK from any to any                   # allow all traffic over the tunnel

sudo ufw allow in on $ETH_LINK to any port 22 proto tcp          # allow ssh connections
sudo ufw allow in on $ETH_LINK to any port 80 proto tcp          # allow nginx to be reachable locally
sudo ufw allow in on $ETH_LINK to any port 443 proto tcp         # 

sudo ufw allow in on $WG_LINK to any port $BT_PORT proto tcp     # allow deluge to be externally reachable through the tunnel
sudo ufw allow in on $WG_LIBK to any port $BT_PORT proto udp     #

sudo ufw allow out on $ETH_LINK to $NFS_IP port 2049 proto tcp   # allow nfs comms
sudo ufw allow out on $ETH_LINK to $NFS_IP port 2049 proto udp   #
sudo ufw allow out on $ETH_LINK to $NFS_IP port 111 proto tcp    #
sudo ufw allow out on $ETH_LINK to $NFS_IP port 111 proto udp    #
sudo ufw allow out on $ETH_LINK to $NFS_IP port 892 proto udp    #

sudo ufw allow out on $ETH_LINK to $MEDIA_SERVER_IP port $MEDIA_SERVER_PORT proto tcp  # optional communication towards eg. plex

# 5. configure the nfs share
sudo mkdir -p $NFS_MNT
sudo mount -t nfs $NFS_PATH $NFS_MNT

# 6. enable the firewall
sudo ufw --force enable
