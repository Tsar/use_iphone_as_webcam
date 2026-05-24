#!/bin/bash

IPHONE_IP="${IPHONE_IP:-172.20.10.1}"

# Re-create video device
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback video_nr=10 card_label="iPhone Camera" exclusive_caps=1

# Use rtsp stream as webcam (video only)
ffmpeg -re -rtsp_transport udp -fflags nobuffer -flags low_delay -i rtsp://admin:admin@${IPHONE_IP}:8554/live -r 30 -vcodec rawvideo -pix_fmt yuyv422 -f v4l2 /dev/video10
