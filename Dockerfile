#
# --- basis for image from Ubuntu ---
FROM ubuntu:22.04 AS build-base-image
LABEL maintainer="TUM Hydromechanics in persona of Simon Wenczowski <simon.wenczowski@tum.de>"
SHELL ["/bin/bash", "-c"]

# --- setting versions for "our" main systems ---
ENV CMAKE_VER="3.23.2"
ENV NINJA_VER="1.11.1"
ENV OMPI_VER="4.1.4"
ENV HDF5_VER="1.14.0"

# setting up the basic environment (with few convenience packages)
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install --no-install-recommends make wget ca-certificates unzip bzip2 time zlib1g-dev vim rsync libucx-dev git gcc g++ gfortran && \
    apt-get clean

ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz"
RUN mkdir /tmp/cmake-install && \
    cd /tmp/cmake-install && \
    wget --no-verbose $CMAKE_URL && \
    tar -xf cmake-${CMAKE_VER}-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    cd / && \
    rm -rf /tmp/cmake-install 

ARG NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v${NINJA_VER}/ninja-linux.zip"
RUN mkdir /tmp/ninja-install && \
    cd /tmp/ninja-install && \
    wget --no-verbose $NINJA_URL && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    cd / && \
    rm -rf /tmp/ninja-install

# CPU architecture for optimizations and default compiler flags 
ENV CC="gcc"
ENV CXX="g++"
ENV FC="gfortran"

ENV CPU_ARCH="x86-64-v2"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"
ENV FFLAGS="-march=${CPU_ARCH}"
ENV FCFLAGS=$FFLAGS

# Download and build OpenMPI (includes radical cleaning)
COPY build-openmpi.sh /opt/
RUN /opt/build-openmpi.sh
ENV MPI_HOME="/opt/openmpi/${OMPI_VER}/install"
ENV PATH="${MPI_HOME}/bin:${PATH}"

# Download and build HDF5 (includes radical cleaning)
COPY build-hdf5.sh /opt/
RUN /opt/build-hdf5.sh
ENV HDF5_ROOT="/opt/hdf5/${HDF5_VER}/install"
ENV PATH="${HDF5_ROOT}/bin:${PATH}"