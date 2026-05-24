#!/bin/bash

ffplay -rtsp_transport udp -fflags nobuffer -flags low_delay -framedrop -strict experimental rtsp://admin:admin@192.168.1.245:8554/live
#
## or sometimes faster:
#
#ffplay -rtsp_transport udp -fflags nobuffer -flags low_delay -probesize 32 -analyzeduration 0 -sync video rtsp://admin:admin@192.168.1.245:8554/live
