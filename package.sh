#!/bin/bash
source /etc/profile.d/rvm.sh;
fpm \
-s dir \
-t rpm \
-n ffmpeg \
--iteration $1 \
--version $2 \
--vendor "Inuits" \
--description "FFmpeg is a very fast video and audio converter. It can also grab from a live audio/video source. The command line interface is designed to be intuitive, in the sense that ffmpeg tries to figure out all the parameters, when possible. You have usually to give only the target bitrate you want. FFmpeg can also convert from any sample rate to any other, and resize video on the fly with a high quality polyphase filter." \
-m "Christophe Vanlancker <carroarmato0@inuits.eu>" \
--prefix /usr/ \
-C $HOME/ffmpeg_build/usr/;
mv *.rpm ./workspace;
