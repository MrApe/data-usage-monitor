#!/bin/sh

[ "$1" != "" ] && DEV="$1" || DEV=eth0

STATISTICS="/sys/class/net/${DEV}/statistics"
PREFIX="/mnt/usb"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
MONTH=$(date +%y-%m)
FILE="${PREFIX}/usage_${DEV}_${MONTH}.log"

TX_BYTES=$(cat "${STATISTICS}/tx_bytes")
RX_BYTES=$(cat "${STATISTICS}/rx_bytes")
SUM=$(( $RX_BYTES + $TX_BYTES ))

touch "$FILE"

LAST=$(tail -n1 "${FILE}" 2>/dev/null)
if [ "$LAST" = "" ]; then
  # try last month file
  LAST_M=$(date -D %s -d $(( $(date +%s) - 86400 )) +%y-%m)
  LAST_M_FILE="${PREFIX}/usage_${DEV}_${LAST_M}.log"
  LAST=$(tail -n1 "${LAST_M_FILE}" 2>/dev/null)
fi


if [ "$LAST" != "" ]; then 
  LAST_TX_BYTES=$(echo "$LAST" | cut -d' ' -f3)
  CHANGE_TX_BYTES=$(( $TX_BYTES - $LAST_TX_BYTES ))
  LAST_RX_BYTES=$(echo "$LAST" | cut -d' ' -f4)
  CHANGE_RX_BYTES=$(( $RX_BYTES - $LAST_RX_BYTES ))
  CHANGE_SUM=$(( $CHANGE_RX_BYTES + $CHANGE_TX_BYTES ))
else
  CHANGE_TX_BYTES=0
  CHANGE_RX_BYTES=0
  CHANGE_SUM=0
fi

FIRST=$(head -n1 "${FILE}" 2>/dev/null)
if [ "$FIRST" != "" ]; then
  FIRST_TX_BYTES=$(echo "$FIRST" | cut -d' ' -f3)
  CHANGE_TX_BYTES_MONTH=$(( $TX_BYTES - $FIRST_TX_BYTES ))
  FIRST_RX_BYTES=$(echo "$FIRST" | cut -d' ' -f4)
  CHANGE_RX_BYTES_MONTH=$(( $RX_BYTES - $FIRST_RX_BYTES ))
  CHANGE_SUM_MONTH=$(( $CHANGE_RX_BYTES_MONTH + $CHANGE_TX_BYTES_MONTH ))
else
  CHANGE_TX_BYTES_MONTH=0
  CHANGE_RX_BYTES_MONTH=0
  CHANGE_SUM_MONTH=0
fi

echo "$DATE $TX_BYTES $RX_BYTES $SUM $CHANGE_TX_BYTES $CHANGE_RX_BYTES $CHANGE_SUM $CHANGE_TX_BYTES_MONTH $CHANGE_RX_BYTES_MONTH $CHANGE_SUM_MONTH" >> "$FILE"
