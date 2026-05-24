# Use iPhone as Webcam on Linux

Small set of scripts that turn an iPhone into a Linux webcam (and optionally a microphone) via an RTSP stream from the phone.

## iPhone side

Install an RTSP server app on the iPhone and start streaming. Either of these works:

- [IP Camera Lite](https://apps.apple.com/us/app/ip-camera-lite/id1013455241)
- [IP Camera Pro](https://apps.apple.com/us/app/ip-camera-pro/id990605467)

Both expose a URL of the form `rtsp://<user>:<pass>@<iphone-ip>:8554/live`. The scripts default to `admin:admin` credentials and `IPHONE_IP=172.20.10.1` (the iPhone's address when your Linux machine joins its Personal Hotspot). Override the IP via the `IPHONE_IP` environment variable, e.g.:

```bash
IPHONE_IP=192.168.1.245 ./use_iphone_as_webcam.sh
```

## Linux side

Requirements:

- `ffmpeg` (and `ffplay` for the preview script)
- `v4l2loopback-dkms` (for the virtual `/dev/video*` device)
- PulseAudio or PipeWire (only the audio-enabled variant needs it)

## Scripts

| Script | Purpose |
| --- | --- |
| `play_stream_from_iphone.sh` | Play the RTSP feed in `ffplay` — useful to verify the iPhone is streaming |
| `use_iphone_as_webcam.sh` | Expose the iPhone as `/dev/video10` (video only) |
| `use_iphone_as_webcam_with_audio.sh` | Same as above, plus a virtual `iPhone_Microphone` PulseAudio source |

## Usage

```bash
./use_iphone_as_webcam.sh
# or, for video + audio:
./use_iphone_as_webcam_with_audio.sh
```

In Chrome, Element, Zoom, etc., pick **iPhone Camera** as the camera. For the audio variant, also pick **iPhone_Microphone** as the microphone (you may need to restart the app once after first run so it sees the new source).

Stop with `Ctrl-C`. The video loopback device and (for the audio variant) PulseAudio modules stay loaded until reboot — re-running the script is safe and idempotent.
