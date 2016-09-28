# Docker FFPMPEG Build

This provides a Dockerfile based on Centos 6 which will prepare an environment for building FFMPEG together with a number of external libraries.

The Docker build will fetch all packages for building the project as well as download the source code of the various external libraries.
Scripts are included for compiling and packaging the whole after the container is started.
The end result is an RPM package with a statically compiled binary of FFMPEG.

## Building
```
docker build -t carroarmato0/ffmpeg:v1 .
```

## Launching the container
```
docker run -i -v ${PWD}:/root/workspace -t carroarmato0/ffmpeg:v1 /bin/bash
```

## Compiling all the libraries and FFMPEG
```
cd ~
./build-all.sh;
```

## Packaging FFMPEG
```
cd ~
./package-ffmpeg.rpm;
```
