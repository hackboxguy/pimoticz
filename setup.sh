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

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing

#install dependencies
printf "Installing dependencies ................................ "
DEBIAN_FRONTEND=noninteractive apt-get install -qq avahi-daemon avahi-discover libnss-mdns avahi-utils nodejs mosquitto mosquitto-clients jq < /dev/null > /dev/null
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


#prepare avahi publish 
printf "Preparing for avahi-publish ............................ "
sed -i "s/pimoticz\(.*\)/$HOST_NAME\"/g" avahi-publish-media-mux.sh
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


#set hostname
printf "Setting hostname ....................................... "
echo "$HOST_NAME" > /etc/hostname
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


#setup auto startup script
printf "Customizing rc.local ................................... "
cp rc.local /etc/
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


printf "Enabling ssh server .................................... "
systemctl enable ssh 1>/dev/null 2>/dev/null
systemctl start ssh 1>/dev/null 2>/dev/null
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
curl -L https://install.domoticz.com | bash /dev/stdin "--unattended"
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


printf "Installing domoticz-plugins............................. "
git clone --quiet https://github.com/stas-demydiuk/domoticz-plugins-manager.git /home/pi/domoticz/plugins/plugins-manager > /dev/null
git clone --quiet https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git /home/pi/domoticz/plugins/zigbee2mqtt > /dev/null
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

systemctl --quiet enable domoticz.service
systemctl --quiet restart domoticz.service

sync

echo   "Setup completed successfully! Reboot the board ......... "
