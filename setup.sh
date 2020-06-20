#!/bin/sh
#./setup.sh -n 1 
USAGE="usage:$0 -h <hostname> "
#SLAVE_NUM="none"
HOST_HAME="pimoticz"
while getopts h: f
do
	case $f in
	#t) TYPE=$OPTARG ;;
	h) HOST_NAME=$OPTARG ;;
	esac
done

#if [ $# -lt 2  ]; then
#	echo $USAGE
#	exit 1
#fi

if [ $(id -u) -ne 0 ]; then
	echo "Please run setup as root ==> sudo ./setup.sh -h my-optional-hostname"
	exit
fi

#case $SLAVE_NUM in
#   ''|*[!0-9]*)
#		echo "Error: $SLAVE_NUM is not a number" && exit 1 ;;
#    *) 
#		NUM=$(printf "%04d" $SLAVE_NUM) ;;
#esac

#printf "Installing auto-startup-player ......................... "
#rm -rf media-mux-autoplay.sh >/dev/null #remove any existing solft-link
#if [ $NUM = "0001" ]; then
#	ln -s media-mux-autoplay-master.sh media-mux-autoplay.sh
#else
#	ln -s media-mux-autoplay-slave.sh media-mux-autoplay.sh
#fi
#test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing

#install dependencies
printf "Installing dependencies ................................ "
DEBIAN_FRONTEND=noninteractive apt-get install -qq avahi-daemon avahi-discover libnss-mdns avahi-utils nodejs mosquitto mosquitto-clients < /dev/null > /dev/null
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
#pushd .
#cd /opt/zigbee2mqtt
#npm ci
#popd
npm ci --prefix /opt/zigbee2mqtt > "/dev/null" 2>&1
systemctl --quiet enable zigbee2mqtt.service
systemctl --quiet start zigbee2mqtt
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

printf "Installing domoticz..................................... "
curl -L https://install.domoticz.com | bash
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"


printf "Installing domoticz-plugins............................. "
pushd .
cd /home/pi/domoticz/plugins/
git clone --quiet https://github.com/stas-demydiuk/domoticz-plugins-manager.git plugins-manager > /dev/null
git clone --quiet https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git zigbee2mqtt > /dev/null
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"
popd

systemctl --quiet enable domoticz.service
systemctl --quiet restart domoticz.service

#printf "Forcing audio output to analog-out ..................... "
#amixer cset numid=3 1 > /dev/null #0-automatic 1-analog 2-hdmi
#test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

#printf "Compiling media-mux-controller-server................... "
#gcc media-mux-controller.c -o media-mux-controller 1>/dev/null 2>/dev/null
#test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

#for master, enable dhcp server
#if [ $NUM = "0001" ]; then
#	sudo apt-get -y install isc-dhcp-server
#	cp dhcpd.conf /etc/dhcp/
#fi

sync

echo   "Setup completed successfully! Reboot the board ......... "
