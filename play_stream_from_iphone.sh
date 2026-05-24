#!/bin/bash

IPHONE_IP="${IPHONE_IP:-172.20.10.1}"

ffplay -rtsp_transport udp -fflags nobuffer -flags low_delay -framedrop -strict experimental rtsp://admin:admin@${IPHONE_IP}:8554/live
#
## or sometimes faster:
#
#ffplay -rtsp_transport udp -fflags nobuffer -flags low_delay -probesize 32 -analyzeduration 0 -sync video rtsp://admin:admin@${IPHONE_IP}:8554/live
