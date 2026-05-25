# Use iPhone as Webcam on Linux

Turn an iPhone into a Linux webcam via an RTSP stream from the phone.

## iPhone side

Install an RTSP server app on the iPhone and start streaming. Either of these works:

- [IP Camera Lite](https://apps.apple.com/us/app/ip-camera-lite/id1013455241)
- [IP Camera Pro](https://apps.apple.com/us/app/ip-camera-pro/id990605467)

Both expose a URL of the form `rtsp://<user>:<pass>@<iphone-ip>:8554/live`. The instructions below default to `admin:admin` credentials and `172.20.10.1` as the iPhone IP (its address when your Linux machine joins its Personal Hotspot).

**Recommended resolution:** 1920×1080 for full HD streaming, or 1280×720 if your CPU or network connection is limited.

---

## Recommended method: OBS + obs-gstreamer (low latency)

This method feeds the RTSP stream directly into OBS Studio via a GStreamer pipeline, with near-zero latency (~2–3 frames). No v4l2loopback involved.

For video calls (Zoom, Meet, etc.) you can use OBS's built-in **Virtual Camera** to expose the result as a regular webcam device.

### 1. Install OBS Studio

Follow the [official OBS Linux installation guide](https://obsproject.com/wiki/install-instructions/linux).

### 2. Install GStreamer packages

```bash
sudo apt install gstreamer1.0-libav gstreamer1.0-rtsp
```

### 3. Install obs-gstreamer plugin

Download the prebuilt binary and place it in OBS's user plugin directory:

```bash
curl -L https://github.com/fzwoch/obs-gstreamer/releases/download/v0.4.1/obs-gstreamer.zip -o /tmp/obs-gstreamer.zip
mkdir -p ~/.config/obs-studio/plugins/obs-gstreamer/bin/64bit
unzip -p /tmp/obs-gstreamer.zip linux/obs-gstreamer.so \
    > ~/.config/obs-studio/plugins/obs-gstreamer/bin/64bit/obs-gstreamer.so
```

No `sudo` needed — OBS scans that directory automatically on startup.

### 4. Add a GStreamer source in OBS

Restart OBS, then in your scene add a new source: **GStreamer Source**.

Set the **Pipeline** to:

```
rtspsrc location=rtsp://admin:admin@172.20.10.1:8554/live latency=0 protocols=4 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! video.
```

(`protocols=4` = TCP, which avoids packet loss artifacts)

### 5. Configure the source settings

In the source properties, apply these settings:

| Setting | Value |
| --- | --- |
| Use pipeline time stamps (video) | ☐ off |
| Sync appsink to clock (video) | ☐ off |
| Drop video when sink is not fast enough | ☑ on |
| Disable buffering in OBS | ☑ on |

> **Why:** with timestamps and clock sync enabled, GStreamer buffers ~2 seconds of frames at startup while aligning the iPhone's stream clock to the local system clock — causing permanent latency. Disabling them makes frames pass through immediately.

### 6. OBS settings

**Settings → Video:**
| Setting | Value |
| --- | --- |
| Base (Canvas) Resolution | 1920×1080 |
| Output (Scaled) Resolution | 1920×1080 |
| FPS | 30 |

**Settings → Audio:**
| Setting | Value |
| --- | --- |
| Sample Rate | 48 kHz |
| Channels | Stereo |

**Settings → Output** — depends on your hardware:

*Modern CPU (e.g. AMD Ryzen 7 7735U):*
| Setting | Value |
| --- | --- |
| Video Bitrate | 6000 kbps |
| Audio Bitrate | 160 kbps |
| Video Encoder | Software (x264) |
| Encoder Preset | fast |
| Audio Encoder | AAC |

*Older CPU with NVIDIA GPU (e.g. i7-2600K + RTX 2070):*
| Setting | Value |
| --- | --- |
| Video Bitrate | 6000 kbps |
| Audio Bitrate | 160 kbps |
| Video Encoder | Hardware (NVENC, H.264) |
| Encoder Preset | P7: Slowest (Best Quality) |
| Audio Encoder | AAC |

Use NVENC when available — it offloads encoding entirely to the GPU (~15% GPU video engine load for H.264), leaving the CPU free. HEVC NVENC is also an option (~30% GPU video engine load) and gives better quality at the same bitrate, but YouTube re-encodes everything anyway so H.264 is the safer choice for streaming. HEVC is more useful for local recordings (smaller file sizes at the same quality).

### 7. For video calls: use OBS Virtual Camera

Click **Start Virtual Camera** in OBS. Any video call app (Zoom, Google Meet, Teams, etc.) will see an **OBS Virtual Camera** device — select it as your camera.

### Alternative pipeline: video + audio via uridecodebin

If you want to also capture the iPhone's microphone through the RTSP stream (e.g. with a DJI Mic connected to the iPhone), use this pipeline instead:

```
uridecodebin uri=rtsp://admin:admin@172.20.10.1:8554/live name=dec dec. ! videoconvert ! video. dec. ! audioconvert ! audio.
```

Also uncheck **Use pipeline time stamps (audio)** and **Sync appsink to clock (audio)**, and check **Drop audio when sink is not fast enough** in the source settings.

> ⚠️ **Caveats:** `uridecodebin` internally creates its own `rtspsrc` with a default jitter buffer that cannot be disabled from the pipeline string. This causes:
> - **Artifacts on motion** — the jitter buffer struggles to keep up when H.264 bitrate spikes due to movement
> - **~200 ms extra latency** compared to the video-only pipeline
>
> Audio and video from this pipeline are in sync with each other (GStreamer handles A/V sync internally), so no manual sync offset is needed between them. But if quality matters, use the video-only pipeline above and handle audio separately.

---

## Legacy method: v4l2loopback scripts

> ⚠️ **These scripts have significant latency (~500 ms) in OBS and video call apps.** The delay comes from the v4l2loopback kernel buffer and how apps read from virtual camera devices. If you use these, you'll need to compensate with a **~550 ms sync offset on your microphone** in OBS (Audio Mixer → ⚙ → Advanced Audio Properties → Sync Offset).
>
> The recommended OBS + obs-gstreamer method above does not have this problem.

These scripts are still useful if you need the virtual camera device outside of OBS (e.g., in a browser-based video call app without OBS running).

### Requirements

- `ffmpeg` (and `ffplay` for the preview script)
- `v4l2loopback-dkms`
- PulseAudio or PipeWire (audio variant only)

```bash
sudo apt install ffmpeg v4l2loopback-dkms
```

### Scripts

| Script | Purpose |
| --- | --- |
| `play_stream_from_iphone.sh` | Play the RTSP stream in `ffplay` — useful to verify the iPhone is streaming. Renders directly to screen with no virtual camera layer, so **no latency issues** |
| `legacy_use_iphone_as_webcam.sh` | Expose the iPhone as `/dev/video10` (video only) |
| `legacy_use_iphone_as_webcam_with_audio.sh` | Same as above, plus a virtual `iPhone_Microphone` PulseAudio source |

### Usage

```bash
./legacy_use_iphone_as_webcam.sh
# or, for video + audio:
./legacy_use_iphone_as_webcam_with_audio.sh
```

In Chrome, Zoom, etc., pick **iPhone Camera** as the camera. For the audio variant, also pick **iPhone_Microphone** as the microphone (you may need to restart the app once after first run so it sees the new source).

Stop with `Ctrl-C`. The video loopback device and (for the audio variant) PulseAudio modules stay loaded until reboot — re-running the script is safe.

### Environment variables

Both the legacy scripts and `play_stream_from_iphone.sh` respect these variables:

| Variable | Default | Description |
| --- | --- | --- |
| `IPHONE_IP` | `172.20.10.1` | iPhone's IP address |
| `RTSP_TRANSPORT` | `tcp` (legacy scripts) / `tcp` (play script) | `tcp` or `udp`. TCP is reliable but adds latency; UDP is lower latency but may produce decode errors on a lossy hotspot connection |

Example:

```bash
IPHONE_IP=192.168.1.245 ./legacy_use_iphone_as_webcam.sh
```
