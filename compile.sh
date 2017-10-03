#!/bin/bash
export PATH=$PATH:/usr/local/bin:$HOME/bin;

# Build nasm
echo "================"
echo "== BUILD NASM =="
echo "================"
cd ~/nasm_sources;
./configure --prefix=/usr;
make && make install;
# Compile YASM
echo "================"
echo "== BUILD YASM =="
echo "================"
cd ~/ffmpeg_sources;
cd yasm;
autoreconf -fiv;
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin";
make && make install && make distclean;
# Compile libx264
echo "==================="
echo "== BUILD libx264 =="
echo "==================="
cd ~/ffmpeg_sources;
cd x264;
bash -l -c "export PKG_CONFIG_PATH=\"$HOME/ffmpeg_build/lib/pkgconfig\"; ./configure --prefix=\"$HOME/ffmpeg_build\" --bindir=\"$HOME/bin\" --enable-static; make && make install && make distclean;"
# Compile libx265
echo "==================="
echo "== BUILD libx265 =="
echo "==================="
cd ~/ffmpeg_sources/x265/build/linux;
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source;
make && make install;
# Compile libfdk_aac
echo "======================"
echo "== BUILD libfdk_aac =="
echo "======================"
cd ~/ffmpeg_sources;
cd fdk-aac;
autoreconf -fiv;
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;
make && make install && make distclean;
# Compile libmp3lame
echo "======================"
echo "== BUILD libmp3lame =="
echo "======================"
cd ~/ffmpeg_sources;
cd lame-3.99.5;
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm;
make && make install && make distclean;
# Compile libopus
echo "==================="
echo "== BUILD libopus =="
echo "==================="
cd ~/ffmpeg_sources;
cd opus;
autoreconf -fiv;
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;
make && make install && make distclean;
# Compile libogg
echo "=================="
echo "== BUILD libogg =="
echo "=================="
cd ~/ffmpeg_sources;
cd libogg-1.3.2;
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;
make && make install && make distclean;
# Compile libvorbis
echo "====================="
echo "== BUILD libvorbis =="
echo "====================="
cd ~/ffmpeg_sources;
cd libvorbis-1.3.5;
LDFLAGS="-L$HOME/ffmeg_build/lib";
CPPFLAGS="-I$HOME/ffmpeg_build/include";
./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared;
make && make install && make distclean;
# Compile libtheora
echo "====================="
echo "== BUILD libtheora =="
echo "====================="
cd ~/ffmpeg_sources;
cd libtheora-1.1.1;
LDFLAGS="-L$HOME/ffmeg_build/lib";
CPPFLAGS="-I$HOME/ffmpeg_build/include";
./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared;
make && make install && make distclean;
# Compile libvpx
echo "=================="
echo "== BUILD libvpx =="
echo "=================="
cd ~/ffmpeg_sources;
cd libvpx;
./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-mmx;
make && make install && make clean;
# Compile FFMPEG
echo "=================="
echo "== BUILD FFMPEG =="
echo "=================="
cd ~/ffmpeg_sources;
cd ffmpeg;
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig";
./configure \
  --prefix="$HOME/ffmpeg_build/usr" \
  --extra-cflags="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -fPIC -I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --pkg-config-flags="--static" \
  --enable-runtime-cpudetect \
  --enable-postproc \
  --enable-avfilter \
  --enable-pthreads \
  --enable-gpl \
  --enable-nonfree \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libtheora \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265;
make && make install && make distclean;
hash -r
