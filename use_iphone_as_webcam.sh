#!/bin/bash

# Re-create video device
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback video_nr=10 card_label="iPhone Camera" exclusive_caps=1

# Use rtsp stream as webcam (video only)
ffmpeg -re -rtsp_transport udp -fflags nobuffer -flags low_delay -i rtsp://admin:admin@192.168.1.245:8554/live -map 0:v -r 30 -vcodec rawvideo -pix_fmt yuyv422 -f v4l2 /dev/video10
