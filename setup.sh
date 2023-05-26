#!/bin/sh
#./setup.sh -h hostname
USAGE="usage:$0 -h <hostname> "
HOST_HAME="pimoticz"
while getopts h: f
do
	case $f in
	#t) TYPE=$OPTARG ;;
	h) HOST_NAME=$OPTARG ;;
	esac
done


if [ $(id -u) -ne 0 ]; then
	echo "Please run setup as root ==> sudo ./setup.sh -h my-optional-hostname"
	exit
fi

printf "Installing dependencies ................................ "
#curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -fsSL https://deb.nodesource.com/setup_16.x > /tmp/new-node-install.sh
chmod +x /tmp/new-node-install.sh
/tmp/new-node-install.sh 1>/dev/null 2>/dev/null
DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing < /dev/null > /dev/null

#install dependencies
#printf "Installing dependencies ................................ "
DEBIAN_FRONTEND=noninteractive apt-get install -qq avahi-daemon avahi-discover libnss-mdns avahi-utils nodejs git make g++ gcc mosquitto mosquitto-clients jq < /dev/null > /dev/null
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


#prepare avahi publish 
printf "Preparing for avahi-publish ............................ "
sed -i "s/pimoticz\(.*\)/$HOST_NAME\"/g" avahi-publish-media-mux.sh
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


#setup auto startup script
printf "Customizing rc.local ................................... "
cp rc.local /etc/
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


printf "Installing zigbee2mqtt.................................. "
git clone --quiet https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt > /dev/null
chown -R pi:pi /opt/zigbee2mqtt
cp configuration.yaml /opt/zigbee2mqtt/data/
cp zigbee2mqtt.service /etc/systemd/system/
npm ci --prefix /opt/zigbee2mqtt > "/dev/null" 2>&1
systemctl --quiet enable zigbee2mqtt.service
systemctl --quiet start zigbee2mqtt
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


printf "Installing domoticz..................................... "
curl -sSfL https://install.domoticz.com | bash /dev/stdin "--unattended"
#./install-domoticz.sh --unattended 1>/dev/null 2>/dev/null
#test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

#printf "Installing domoticz-plugins............................. "
#git clone --quiet https://github.com/stas-demydiuk/domoticz-plugins-manager.git /home/pi/domoticz/plugins/plugins-manager > /dev/null
git clone --quiet https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git /home/pi/domoticz/plugins/zigbee2mqtt > /dev/null
#test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

service domoticz.sh stop
cp domoticz.db /home/pi/domoticz/
mkdir -p /home/pi/domoticz/scripts/dzVents/generated_scripts/
cp domoticz-scripts/*.lua /home/pi/domoticz/scripts/dzVents/generated_scripts/
service domoticz.sh start
sync

echo   "Setup completed successfully! Reboot the board ......... "
