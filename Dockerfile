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

ADD compile.sh /root/compile.sh
RUN chmod +x /root/compile.sh
RUN /root/compile.sh

ADD package.sh /root/package.sh
RUN chmod +x /root/package.sh
RUN /root/package.sh $ITERATION $FFMPEG_RELEASE
