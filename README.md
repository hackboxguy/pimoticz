# pimoticz
domoticz on raspi:
This repo adds domoticz and other dependencies to turn your raspi into a home-automation-server.

steps for installation.
  1. prepare the raspi with freshly created Raspberry Pi OS(32-bit) sdcard.
  2. boot the raspi and do the startup wizard based steps for setting the languae and time-zone.
  3. open terminal on raspi and run the following 5 commands,
    * `cd /home/pi`
    * `git clone https://github.com/hackboxguy/pimoticz.git`
    * `cd pimoticz`
    * `sudo ./setup.sh` (or sudo ./setup.sh -h my-pimoticz-hostname)
    * `sudo reboot`
