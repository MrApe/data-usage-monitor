#!/bin/sh

PREFIX="/mnt/usb"

function humanize() {
  X=$1
  if [ $X -lt 1000 ]; then
    X="$X Byte"
  else
    X=$(( $X / 1000 ))
    if [ $X -lt 1000 ]; then
      X="$X kB"
    else
      X=$(( $X / 1000 ))
      if [ $X -lt 1000 ]; then
        X="$X MB"
      else
        X=$(( $X / 1000 ))
        if [ $X -lt 1000 ]; then
          X="$X GB"
        else
          X="$(( $X / 1000 )) TB"
        fi
      fi
    fi
  fi
  echo $X
}

if [ "$1" = "report" ]; then
  echo "MONTH    TX       RX       SUM"
  cd $PREFIX
  for f in $(ls usage_*); do
    LAST=$(tail -n1 $f)
    MONTH=$(echo $LAST | sed 's/-[0-9][0-9] .*//g')
    TX=$(humanize $(echo $LAST | cut -d' ' -f9) )
    RX=$(humanize $(echo $LAST | cut -d' ' -f10) )
    SUM=$(humanize $(echo $LAST | cut -d' ' -f11) )
    echo "$MONTH  $TX   $RX   $SUM"
  done
  cd - >/dev/null 2>&1
  exit 0
fi

[ "$1" != "" ] && DEV="$1" || DEV=eth0

STATISTICS="/sys/class/net/${DEV}/statistics"
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
