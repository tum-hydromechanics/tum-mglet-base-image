#
# --- basis for image from Ubuntu ---
FROM ubuntu:22.04 AS build-base-image
LABEL maintainer="Simon Wenczowski <simon.wenczowski@tum.de>"
SHELL ["/bin/bash", "-c"]

# setting up the basic environment (with few convenience packages)
RUN apt -y update && apt -y upgrade && \
    apt -y install wget unzip gnupg git-lfs zlib1g-dev vim time rsync && \
    apt clean

# setting the keys (required for Intel compilers)
RUN cd /tmp
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
RUN apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
RUN rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
RUN echo "deb https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list
RUN apt update

# Fetch and install updated CMake in /usr/local
ENV CMAKE_VER="3.23.2"
ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz"
RUN mkdir /tmp/cmake-install && \
    cd /tmp/cmake-install && \
    wget --no-verbose $CMAKE_URL && \
    tar -xf cmake-${CMAKE_VER}-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    cd / && \
    rm -rf /tmp/cmake-install

# Fetch and install updated Ninja-build in /usr/local
ARG NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-linux.zip"
RUN mkdir /tmp/ninja-install && \
    cd /tmp/ninja-install && \
    wget --no-verbose $NINJA_URL && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    cd / && \
    rm -rf /tmp/ninja-install

ENV HDF5_VER="1.14.0"
COPY build-hdf5.sh /opt/



# ---------------------------------------------------------------------------- #
# Intel oneAPI compilers, Intel MPI image
FROM build-base-image AS intel-impi-image
LABEL description="Intel compilers with Intel MPI and HDF5 image for building Fortran applications"

# installing the compilers (+ Intel-MPI)
RUN apt -y install intel-oneapi-compiler-dpcpp-cpp-2022.2.1
RUN apt -y install intel-oneapi-compiler-fortran-2022.2.1
RUN apt -y install intel-oneapi-mpi-devel-2021.7.1
RUN apt -y install gcc g++ make

# CPU architecture for optimizations and default compiler flags
ENV CC="icx"
ENV CXX="icpx"
ENV FC="ifx"

ENV CPU_ARCH="x86-64-v2"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"
ENV FFLAGS="-march=${CPU_ARCH}"
ENV FCFLAGS=$FFLAGS

# Download and build HDF5
RUN source /opt/intel/oneapi/setvars.sh && /opt/build-hdf5.sh
ENV HDF5_ROOT="/opt/hdf5/${HDF5_VER}/install"
ENV PATH="${HDF5_ROOT}/bin:${PATH}"

# Update bashrc file (paths are set here)
RUN echo "source /opt/intel/oneapi/setvars.sh" >> /root/.bashrc


# ---------------------------------------------------------------------------- #
# GNU compilers, OpenMPI image
FROM build-base-image AS gnu-ompi-image
LABEL description="GNU compilers with OpenMPI and HDF5 image for building Fortran applications"

# Install GNU compilers and UCX
RUN apt -y update
RUN apt -y install build-essential
RUN apt -y install gfortran
RUN apt -y install libucx-dev
RUN apt clean

# CPU architecture for optimizations and default compiler flags
ENV CC="gcc"
ENV CXX="g++"
ENV FC="gfortran"

ENV CPU_ARCH="x86-64-v2"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"
ENV FFLAGS="-march=${CPU_ARCH}"
ENV FCFLAGS=$FFLAGS

# Download and build OpenMPI
ENV OMPI_VER="4.1.4"
COPY build-openmpi.sh /opt/
RUN /opt/build-openmpi.sh
ENV MPI_HOME="/opt/openmpi/${OMPI_VER}/install"
ENV PATH="${MPI_HOME}/bin:${PATH}"

# Download and build HDF5
RUN /opt/build-hdf5.sh
ENV HDF5_ROOT="/opt/hdf5/${HDF5_VER}/install"
ENV PATH="${HDF5_ROOT}/bin:${PATH}"
