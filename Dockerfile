FROM centos:6
MAINTAINER Christophe Vanlancker <carroarmato0@inuits.eu>

ENV RUBY_VERSION 1.9.3
ENV PATH $PATH:/usr/local/bin:$HOME/bin
ENV PKG_CONFIG_PATH "$HOME/ffmpeg_build/lib/pkgconfig"

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
    #nasm \
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
    curl -L -O http://www.nasm.us/pub/nasm/releasebuilds/2.12.02/nasm-2.12.02.tar.xz; \
    tar -xf nasm-2.12.02.tar.xz --strip-components=1; \
    ./configure --prefix=/usr; \
    make; make install;

    # Compile YASM
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://github.com/yasm/yasm.git; \
    cd yasm; \
    autoreconf -fiv; \
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"; \
    make && make install && make distclean;

    # Compile libx264
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://git.videolan.org/x264; \
    cd x264; \
    bash -l -c "export PKG_CONFIG_PATH=\"$HOME/ffmpeg_build/lib/pkgconfig\"; ./configure --prefix=\"$HOME/ffmpeg_build\" --bindir=\"$HOME/bin\" --enable-static; make && make install && make distclean;"
    # Compile libx265
RUN cd ~/ffmpeg_sources; \
    hg clone https://bitbucket.org/multicoreware/x265; \
    cd ~/ffmpeg_sources/x265/build/linux; \
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source; \
    make; make install;

    # Compile libfdk_aac
RUN cd ~/ffmpeg_sources; \
    git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac; \
    cd fdk-aac; \
    autoreconf -fiv; \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared; \
    make; make install; make distclean;

    # Compile libmp3lame
RUN cd ~/ffmpeg_sources; \
    curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz; \
    tar xzvf lame-3.99.5.tar.gz; \
    cd lame-3.99.5; \
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm; \
    make; make install; make distclean;

    # Compile libopus
RUN cd ~/ffmpeg_sources; \
    git clone http://git.opus-codec.org/opus.git; \
    cd opus; \
    autoreconf -fiv; \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared; \
    make; make install; make distclean;

    # Compile libogg
RUN cd ~/ffmpeg_sources; \
    curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz; \
    tar xzvf libogg-1.3.2.tar.gz; \
    cd libogg-1.3.2; \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared; \
    make; make install; make distclean;

    # Compile libvorbis
RUN cd ~/ffmpeg_sources; \
    curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz; \
    tar xzvf libvorbis-1.3.5.tar.gz; \
    cd libvorbis-1.3.5; \
    LDFLAGS="-L$HOME/ffmeg_build/lib"; \
    CPPFLAGS="-I$HOME/ffmpeg_build/include" ; \
    ./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared; \
    make; make install; make distclean;

    # Compile libvpx
RUN cd ~/ffmpeg_sources; \
    # 1.6.0 too new for Centos 6, requires higher version of nasm and by extend, libc. Should work on Centos7 though
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git; \
    # git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git; \
    cd libvpx; \
    # git checkout v1.4.0; \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-mmx; \
    make; make install; make clean;

    # Compile FFMPEG
RUN cd ~/ffmpeg_sources; \
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg; \
    cd ffmpeg; \
    git checkout n$FFMPEG_RELEASE; \
    PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build/usr" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --bindir="$HOME/bin" --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265; \
    make; make install; make distclean; \
    hash -r;

RUN /root/bin/ffmpeg -formats; \
    /root/bin/ffmpeg -codecs; \
    /root/bin/ffmpeg -encoders; \
    /root/bin/ffmpeg -decoders;

RUN bash -l -c "source /etc/profile.d/rvm.sh && fpm -s dir -t rpm -n ffmpeg --version $FFMPEG_RELEASE --vendor \"Inuits\" --description \"FFmpeg is a very fast video and audio converter. It can also grab from a live audio/video source. The command line interface is designed to be intuitive, in the sense that ffmpeg tries to figure out all the parameters, when possible. You have usually to give only the target bitrate you want. FFmpeg can also convert from any sample rate to any other, and resize video on the fly with a high quality polyphase filter.\" -m \"Christophe Vanlancker <carroarmato0@inuits.eu>\" -C $HOME/ffmpeg_build/;"
RUN ls -hal;
