FROM centos:6
MAINTAINER Christophe Vanlancker <carroarmato0@inuits.eu>

ENV ITERATION 2
ENV RUBY_VERSION 1.9.3
ENV PATH $PATH:/usr/local/bin:$HOME/bin
ENV PKG_CONFIG_PATH "$HOME/ffmpeg_build/lib/pkgconfig"
ENV NASM_RELEASE 2.12.02
ENV LAME_SHORT_RELEASE 3.99
ENV LAME_RELEASE 3.99.5
ENV LIBOGG_RELEASE 1.3.2
ENV LIBVORBIS_RELEASE 1.3.5
ENV LIBVPX_RELEASE 1.6.0
ENV FFMPEG_RELEASE 3.1.3

RUN yum clean all && yum update -y; \
    yum install -y \
    autoconf \
    automake \
    cmake \
    freetype-devel \
    gcc \
    gcc-c++ \
    patch \
    readline \
    readline-devel \
    zlib \
    libyaml-devel \
    libffi-devel \
    openssl-devel \
    bzip2 \
    libtool \
    bison \
    iconv-devel \
    git \
    libtool \
    make \
    mercurial \
    tree \
    nano \
    vim \
    pkgconfig \
    zlib-devel \
    rpm-build;
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN bash -l -c "curl -sL https://get.rvm.io | bash -s stable"
RUN bash -l -c "source /etc/profile.d/rvm.sh && /usr/local/rvm/bin/rvm requirements && rvm install $RUBY_VERSION --autolibs=enabled && rvm use ${RUBY_VERSION}"
RUN echo "source /etc/profile.d/rvm.sh" >> /etc/profile && echo "rvm --default use $RUBY_VERSION" >> /etc/profile
RUN bash -l -c "source /etc/profile.d/rvm.sh && gem update --system && gem install fpm && fpm --version; mkdir ~/ffmpeg_sources;"

    # Compile nasm - version of nasm on Centos6 is 2.06, too old to compile libvpx, but should be ok on Centos7
RUN mkdir ~/nasm_sources; \
    cd ~/nasm_sources; \
    curl -L -O http://www.nasm.us/pub/nasm/releasebuilds/$NASM_RELEASE/nasm-$NASM_RELEASE.tar.xz; \
    tar -xf nasm-$NASM_RELEASE.tar.xz --strip-components=1;

    # Compile YASM
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://github.com/yasm/yasm.git;

    # Compile libx264
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://git.videolan.org/x264;

    # Compile libx265
RUN cd ~/ffmpeg_sources; \
    hg clone https://bitbucket.org/multicoreware/x265;

    # Compile libfdk_aac
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac;

    # Compile libmp3lame
RUN cd ~/ffmpeg_sources; \
    curl -L -O http://downloads.sourceforge.net/project/lame/lame/${LAME_SHORT_RELEASE}/lame-${LAME_RELEASE}.tar.gz; \
    tar xzvf lame-$LAME_RELEASE.tar.gz;

    # Compile libopus
RUN cd ~/ffmpeg_sources; \
    git clone http://git.opus-codec.org/opus.git;

    # Compile libogg
RUN cd ~/ffmpeg_sources; \
    curl -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-$LIBOGG_RELEASE.tar.gz; \
    tar xzvf libogg-$LIBOGG_RELEASE.tar.gz;

    # Compile libvorbis
RUN cd ~/ffmpeg_sources; \
    curl -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-$LIBVORBIS_RELEASE.tar.gz; \
    tar xzvf libvorbis-$LIBVORBIS_RELEASE.tar.gz;

    # Compile libvpx
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git; \
    cd libvpx; \
    git checkout v$LIBVPX_RELEASE;

    # Compile FFMPEG
RUN cd ~/ffmpeg_sources; \
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg; \
    cd ffmpeg; \
    git checkout n$FFMPEG_RELEASE;

RUN echo  $'#!/bin/bash\n\n \
export PATH=$PATH:/usr/local/bin:$HOME/bin;\n \
# Build nasm\n \
echo "================"\n \
echo "== BUILD NASM =="\n \
echo "================"\n \
cd ~/nasm_sources;\n \
./configure --prefix=/usr;\n \
make && make install;\n\n \
# Compile YASM\n \
echo "================"\n \
echo "== BUILD YASM =="\n \
echo "================"\n \
cd ~/ffmpeg_sources;\n \
cd yasm;\n \
autoreconf -fiv;\n \
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin";\n \
make && make install && make distclean;\n\n \
# Compile libx264\n \
echo "==================="\n \
echo "== BUILD libx264 =="\n \
echo "==================="\n \
cd ~/ffmpeg_sources;\n \
cd x264;\n \
bash -l -c "export PKG_CONFIG_PATH=\"$HOME/ffmpeg_build/lib/pkgconfig\"; ./configure --prefix=\"$HOME/ffmpeg_build\" --bindir=\"$HOME/bin\" --enable-static; make && make install && make distclean;"\n\n \
# Compile libx265\n \
echo "==================="\n \
echo "== BUILD libx265 =="\n \
echo "==================="\n \
cd ~/ffmpeg_sources/x265/build/linux;\n \
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source;\n \
make && make install;\n\n \
# Compile libfdk_aac\n \
echo "======================"\n \
echo "== BUILD libfdk_aac =="\n \
echo "======================"\n \
cd ~/ffmpeg_sources;\n \
cd fdk-aac;\n \
autoreconf -fiv;\n \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;\n \
make && make install && make distclean;\n\n \
# Compile libmp3lame\n \
echo "======================"\n \
echo "== BUILD libmp3lame =="\n \
echo "======================"\n \
cd ~/ffmpeg_sources;\n \
cd lame-3.99.5;\n \
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm;\n \
make && make install && make distclean;\n\n \
# Compile libopus\n \
echo "==================="\n \
echo "== BUILD libopus =="\n \
echo "==================="\n \
cd ~/ffmpeg_sources;\n \
cd opus;\n \
autoreconf -fiv;\n \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;\n \
make && make install && make distclean;\n\n \
# Compile libogg\n \
echo "=================="\n \
echo "== BUILD libogg =="\n \
echo "=================="\n \
cd ~/ffmpeg_sources;\n \
cd libogg-1.3.2;\n \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared;\n \
make && make install && make distclean;\n\n \
# Compile libvorbis\n \
echo "====================="\n \
echo "== BUILD libvorbis =="\n \
echo "====================="\n \
cd ~/ffmpeg_sources;\n \
cd libvorbis-1.3.5;\n \
LDFLAGS="-L$HOME/ffmeg_build/lib";\n \
CPPFLAGS="-I$HOME/ffmpeg_build/include";\n \
./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared;\n \
make && make install && make distclean;\n\n \
# Compile libvpx\n \
echo "=================="\n \
echo "== BUILD libvpx =="\n \
echo "=================="\n \
cd ~/ffmpeg_sources;\n \
cd libvpx;\n \
./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-mmx;\n \
make && make install && make clean;\n\n \
# Compile FFMPEG\n \
echo "=================="\n \
echo "== BUILD FFMPEG =="\n \
echo "=================="\n \
cd ~/ffmpeg_sources;\n \
cd ffmpeg;\n \
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig";\n \
./configure \\\n\
  --prefix="$HOME/ffmpeg_build/usr" \\\n\
  --extra-cflags="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -fPIC -I$HOME/ffmpeg_build/include" \\\n\
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \\\n\
  --pkg-config-flags="--static" \\\n\
  --enable-runtime-cpudetect \\\n\
  --enable-postproc \\\n\
  --enable-avfilter \\\n\
  --enable-pthreads \\\n\
  --enable-gpl \\\n\
  --enable-nonfree \\\n\
  --enable-libfdk-aac \\\n\
  --enable-libfreetype \\\n\
  --enable-libmp3lame \\\n\
  --enable-libopus \\\n\
  --enable-libvorbis \\\n\
  --enable-libvpx \\\n\
  --enable-libx264 \\\n\
  --enable-libx265;\n \
make && make install && make distclean;\n \
hash -r;\n' \
>> $HOME/build-all.sh; chmod +x $HOME/build-all.sh;

RUN echo  $'#!/bin/bash\n\n\
source /etc/profile.d/rvm.sh;\n\
fpm \\\n\
-s dir \\\n\
-t rpm \\\n\
-n ffmpeg \\\n\
--iteration $ITERATION \\\n\
--version $FFMPEG_RELEASE \\\n\
--vendor \"Inuits\" \\\n\
--description \"FFmpeg is a very fast video and audio converter. It can also grab from a live audio/video source. The command line interface is designed to be intuitive, in the sense that ffmpeg tries to figure out all the parameters, when possible. You have usually to give only the target bitrate you want. FFmpeg can also convert from any sample rate to any other, and resize video on the fly with a high quality polyphase filter.\" \\\n\
-m \"Christophe Vanlancker <carroarmato0@inuits.eu>\" \\\n\
--prefix /usr/ \\\n\
-C $HOME/ffmpeg_build/usr/;\n\
mv *.rpm ./workspace;\n'\
>> $HOME/package-ffmpeg.sh; chmod +x $HOME/package-ffmpeg.sh;
