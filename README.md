example output BW: https://www.youtube.com/watch?v=UbaBI-XxGbo

do whatever you want with this

## What is this
This takes an image sequence and converts it to a quadtree structured image sequence with a gif/sprite of your choice (place it in res/ and update it in code).

you can set the max and min square size in the subdivide methods (functions?)

## Info
- Reads and Writes **PNG**
- Input goes into **in/** with format **img_#.png**
- Output comes out in **out/** with format **img_#.png**
- Not that slow anymore
- Usage Instructions in Code / when running without args
- Requires C++17 features enabled (thread-pool)

# Credits
[stb_image / stb_image_write](https://github.com/nothings/stb)

[thread-pool](https://github.com/bshoshany/thread-pool) - by recommendation of [ramidzkh](https://github.com/ramidzkh)

# FFMPEG commands

If you have a video file called `bad_apple.mp4`, that's 360p resolution, you can convert it into the input format with
```
ffmpeg -i bad_apple.mp4 -vf "crop=360:360, negate" in/img_%d.png
```

To convert the output frames back into a video (with sound), use:

```
ffmpeg -r 30 -f image2 -s 360x360 -i out/img_%d.png -i bad_apple.mp4 -vcodec libx264 -acodec copy -map 0:v:0 -map 1:a:0 -crf 15 -pix_fmt yuv420p out.mp4
```

# Final procedure

```
1. Download Video
2. ffmpeg -i <name>.mp4 -vf "elbg=8" <name>.mp4
3. ffmpeg -i <name>.mp4 in/img_%d.png
4. amogus BW|Col <start> <end>
5. ffmpeg -r 24 -f image2 -i out/img_%d.png -i <name>.mp4 -vcodec libx264 -acodec copy -map 0:v:0 -map 1:a:0 -crf 15 -pix_fmt yuv420p out.mp4
```
