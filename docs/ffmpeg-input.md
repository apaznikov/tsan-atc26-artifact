# The FFmpeg input clip

The FFmpeg workload transcodes a 100-second clip four ways (libx264, libx265, mjpeg and stream
copy) at a fixed `-threads` value. The clip is not in git or in the image: a prepared copy (78 MB) is an
asset of this repository's GitHub release `inputs-v1`, redistributed under the source's CC BY 3.0 with
attribution, and `env.sh` defaults `ART_FFMPEG_CLIP_URL` to it; it can also be produced from the source by the
exact command below, so the input is reproducible as well as redistributed.

| Item | Value |
|---|---|
| File | `projects/ffmpeg/input/TearsOfSteel-1366x768-100s.mkv` in the harness, 77.8 MB |
| sha256 | `43b0fba97eb05a0e44d7518fe9d6993c140680531a17a240ea6d53582fbe9985` |
| Source | *Tears of Steel* (Blender Foundation, 2012), CC-BY 3.0, https://mango.blender.org/ |
| Source file | `https://download.blender.org/demo/movies/ToS/tears_of_steel_1080p.mov.zip`, 557 MB, sha256 `d87a41de040d3814dbde143e9ab85ef122caf22265f660b0bebf476cd8b357a5` |
| Segment | 100 s from 06:00 |

```
ffmpeg -hide_banner -loglevel error -ss 360 -t 100 -i tears_of_steel_1080p.mov \
       -vf crop=1422:800,scale=1366:768,fps=30 \
       -c:v libx264 -preset medium -b:v 6400k -pix_fmt yuv420p \
       -c:a libvorbis -ar 48000 -ac 2 -y TearsOfSteel-1366x768-100s.mkv
```

The harness reads the clip from `FF_TEST_VIDEO` (default: the path above). The benchmark's
copy arm passes the audio stream through and the encoder arms re-encode it, so the clip keeps an
audio track like the clip it replaces.

## Two deliberate deviations from "scale the source to 1366x768 at 30 fps"

1. **Crop, then scale.** The source is 1920x800 (2.40:1), not 16:9. Scaling it straight to
   1366x768 distorts; padding to 16:9 fills a seventh of every frame with black, which encodes
   almost free and would understate the encoder work the benchmark measures. The clip is cropped
   to 1422x800 (16:9) and then scaled, so every pixel carries content.
2. **Duplicated frames.** The source is 24 fps and the output is 30 fps, so `fps=30` duplicates
   one output frame in five (600 of 3000). Duplicates encode cheaply, so absolute times are a
   little lower than the frame count suggests. Both arms of every ratio encode the same frames,
   so the speedups are unaffected. 30 fps is kept because it matches the retired clip and keeps
   the run durations comparable.

## Comparability with the clip the paper used

| | retired clip (`WatchingEyeTexture.mkv`) | this clip |
|---|---|---|
| resolution / fps / pixel format | 1366x768, 30, yuv420p | 1366x768, 30, yuv420p |
| duration | 100.56 s | 100.00 s |
| video bit rate | 6.41 Mbit/s | 6.52 Mbit/s |
| audio | Vorbis 48 kHz stereo | Vorbis 48 kHz stereo |

The paper's FFmpeg column and the Stage B runs used the retired clip; within the campaign every
configuration shares this clip. A control leg on the campaign compiler with the retired clip, four
configurations, measures the clip's own contribution: its ratios agree with the reference clip's within
their intervals (`CLAIMS.md`, the FFmpeg section at `-threads 4`). Its runs are not shipped, because the
retired clip has no recorded provenance or licence and cannot be redistributed.

Why a real clip and not a synthetic pattern: the one substantial FFmpeg result in the paper
(DynSTC, about 1.12x) depends on the workload having genuinely single-threaded phases; a synthetic
test source compresses trivially and does not exercise them.

`harness/projects/ffmpeg/ensure_input_clip.sh`, run by the FFmpeg build before anything is compiled,
produces the clip by the first of three paths that applies:

1. `ART_FFMPEG_CLIP_URL`: a prepared copy of the reference clip, either a URL or a local path (a plain
   path or `file://`), fetched or copied and in both cases checked against the sha256 above; a mismatch
   deletes the file and refuses, and a local copy is trusted no more for being local. The default is
   the asset of this repository's GitHub release `inputs-v1`
   (`https://github.com/apaznikov/tsan-atc26-artifact/releases/download/inputs-v1/TearsOfSteel-1366x768-100s.mkv`); the artifact's
   Zenodo deposit made when evaluation finishes will carry the same file. Exporting the empty string opts
   out and takes path 3. `docker/run.sh` forwards the variable into the container.
2. `ART_FFMPEG_SOURCE`: a local copy of the unpacked Blender source (`.mov`), cut here with the command
   above.
3. Neither set: the 557 MB Blender source is downloaded, verified against its published sha256, unpacked
   and cut. This is the path when `ART_FFMPEG_CLIP_URL` is exported empty, and the fallback when the release cannot be reached.

Paths 2 and 3 re-encode, and a re-encode's sha256 differs from the reference even under an identical
command, because encoder builds differ. Every run therefore records `input_is_reference: true|false`
beside `input_sha256` in its `meta.json`. A run on a regenerated clip is valid, and its build and run
times are what an evaluator pays; only the comparison of its ratios with the shipped intervals is not
made, since those were measured on the reference clip. Smoke mode uses the same 100 s clip at N = 1.
