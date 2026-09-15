# The FFmpeg input clip

The FFmpeg workload transcodes a 100-second clip with four codecs (libx264, libx265, mjpeg and
stream copy), video only. The clip is not shipped; it is produced from a CC-BY source by the exact
command below, so the input is reproducible rather than redistributed.

Source: *Tears of Steel* (Blender Foundation, 2012), CC-BY 3.0, https://mango.blender.org/download/
(the 1080p MKV). Cut to match the workload the paper used: 1366x768, 30 fps, yuv420p, about
6.4 Mbit/s H.264 in Matroska, 100 seconds.

```
ffmpeg -ss 00:03:00 -t 100 -i tears_of_steel_1080p.mkv \
       -vf scale=1366:768,fps=30 -pix_fmt yuv420p \
       -c:v libx264 -b:v 6400k -maxrate 6400k -bufsize 12800k -an \
       input/clip.mkv
```

`40-perf.sh ffmpeg` runs this command if `input/clip.mkv` is absent and the source file is present
(set `ART_FFMPEG_SOURCE` to its path); with `--smoke` it uses a 10-second cut.

Why a real clip and not a synthetic pattern: the one substantial FFmpeg result in the paper
(DynSTC, about 1.12x) depends on the workload having genuinely single-threaded phases; a synthetic
test source compresses trivially and does not exercise them.

Why not the clip the paper used: it had no recorded provenance or license, so it cannot be
redistributed; the paper's FFmpeg numbers are restated against this input.
