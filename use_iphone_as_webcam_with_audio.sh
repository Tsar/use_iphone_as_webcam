#!/bin/bash

# Re-create video device
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback video_nr=10 card_label="iPhone Camera" exclusive_caps=1

# Create virtual microphone (idempotent — safe to run every time)
pactl list short modules | grep -q 'sink_name=iphone\b' || \
    pactl load-module module-null-sink sink_name=iphone \
        sink_properties=device.description=iPhone_Sink
pactl list short modules | grep -q 'source_name=iphone_mic\b' || \
    pactl load-module module-remap-source master=iphone.monitor \
        source_name=iphone_mic \
        source_properties=device.description=iPhone_Microphone

# Use rtsp stream as webcam
ffmpeg -re -rtsp_transport udp -fflags nobuffer -flags low_delay -i rtsp://admin:admin@192.168.1.245:8554/live -map 0:v -r 30 -vcodec rawvideo -pix_fmt yuyv422 -f v4l2 /dev/video10 -map 0:a -f pulse iphone

# If only video is needed
#ffmpeg -re -rtsp_transport udp -fflags nobuffer -flags low_delay -i rtsp://admin:admin@192.168.1.245:8554/live -r 30 -vcodec rawvideo -pix_fmt yuyv422 -f v4l2 /dev/video10
