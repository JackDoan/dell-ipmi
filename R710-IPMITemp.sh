#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control.
#
# Requires:
# ipmitool – apt-get install ipmitool
# ----------------------------------------------------------------------------------

IPMIHOST=10.3.0.5
IPMIUSER=root
IPMIPW=root

TEMP_WARN="Warning: Temperature is too high! Activating dynamic fan control!"

IPMI () {
	#ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW $@
	ipmitool $@
}

FANS_MAN () {
	IPMI raw 0x30 0x30 0x01 0x00
}

FANS_AUTO () {
	IPMI raw 0x30 0x30 0x01 0x01
}

LCD_MSG () {
  IPMI delloem lcd set mode userdefined $1 &
}


MAXTEMP=30
TEMP=$(IPMI sdr type temperature |grep Ambient |grep degrees |grep -Po '\d{2}' | tail -1)

if [[ $TEMP > $MAXTEMP ]];
  then
    printf "$TEMP_WARN ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    FANS_AUTO
    LCD_MSG 'Hot! Hot! Hot!'
  else
    printf "Temperature is OK ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    echo "Temperature is OK ($TEMP C)"
		printf "Activating manual fan speeds!" | systemd-cat -t R710-IPMI-TEMP
		FANS_MAN
		IPMI raw 0x30 0x30 0x02 0xff ${1:-0x18}
		LCD_MSG 'Whoosh!'
fi
