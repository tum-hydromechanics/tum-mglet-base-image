FROM centos:7 AS build-base-image
LABEL maintainer="Håkon Strandenes <h.strandenes@km-turbulenz.no>"
SHELL ["/bin/bash", "-c"]

# Note: "yum check-update" return code 100 if there are packages to be updated,
# hence the ";" instead of "&&"
#     vim-common for xxd (not obvious)
RUN yum check-update ; \
    yum -y update && \
    yum -y install bash-completion \
                   bzip2 \
                   centos-release-scl \
                   epel-release \
                   file \
                   libcurl-devel \
                   patch \
                   rsync \
                   time \
                   unzip \
                   vim-common \
                   wget \
                   which && \
    yum -y install patchelf rh-python38 rh-python38-python-devel && \
    yum -y update && \
    yum -y --enablerepo="epel" install the_silver_searcher && \
    yum clean all

# Install an updated Git from ius.io and git-lfs from packagecloud.io
#
# rh-git218 does not work with Github actions (too old)
# rh-git227 does not have Git LFS
# so therefore using this approach
RUN yum -y install https://repo.ius.io/ius-release-el7.rpm && \
    yum check-update ; \
    yum -y install git236 && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash && \
    yum -y install git-lfs && \
    yum clean all

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
ARG NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.11.0/ninja-linux.zip"
RUN mkdir /tmp/ninja-install && \
    cd /tmp/ninja-install && \
    wget --no-verbose $NINJA_URL && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    cd / && \
    rm -rf /tmp/ninja-install

ENV HDF5_VER="1.12.2"
COPY build-hdf5.sh /opt/

# Create bashrc file
RUN echo "source scl_source enable rh-python38" >> /opt/bashrc


# ---------------------------------------------------------------------------- #
# Intel oneAPI compilers, Intel MPI image
FROM build-base-image AS intel-impi-image
LABEL description="Intel compilers with Intel MPI and HDF5 image for building Fortran applications"

# Install Intel oneAPI packages (compiler, MPI)
COPY oneAPI.repo /etc/yum.repos.d/
# Cherry-pick packages to minimize image size
#     instead of:
#     yum -y install intel-basekit intel-hpckit
# Package ref: https://oneapi-src.github.io/oneapi-ci/#linux-yum-dnf
RUN yum -y install intel-oneapi-compiler-dpcpp-cpp-2022.1.0 \
                   intel-oneapi-compiler-fortran-2022.1.0 \
                   intel-oneapi-mpi-devel-2021.6.0 \
                   gcc make && \
    yum clean all

# CPU architecture for optimizations and default compiler flags
ENV CC="icx"
ENV CXX="icpx"
ENV FC="ifx"

ENV CPU_ARCH="corei7"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"
ENV FFLAGS="-march=${CPU_ARCH}"
ENV FCFLAGS=$FFLAGS

# Download and build HDF5
RUN source /opt/intel/oneapi/setvars.sh && /opt/build-hdf5.sh
ENV HDF5_ROOT="/opt/hdf5/${HDF5_VER}/install"
ENV PATH="${HDF5_ROOT}/bin:${PATH}"

# Update bashrc file
RUN echo "source /opt/intel/oneapi/setvars.sh" >> /opt/bashrc


# ---------------------------------------------------------------------------- #
# GNU compilers, OpenMPI image
FROM build-base-image AS gnu-ompi-image
LABEL description="GNU compilers with OpenMPI and HDF5 image for building Fortran applications"

# Install GNU compilers and UCX
RUN yum -y install devtoolset-11 devtoolset-11-libasan-devel devtoolset-11-libubsan-devel ucx-devel && \
    yum clean all

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
RUN source scl_source enable devtoolset-11 && /opt/build-openmpi.sh
ENV MPI_HOME="/opt/openmpi/${OMPI_VER}/install"
ENV PATH="${MPI_HOME}/bin:${PATH}"

# Download and build HDF5
RUN source scl_source enable devtoolset-11 && /opt/build-hdf5.sh
ENV HDF5_ROOT="/opt/hdf5/${HDF5_VER}/install"
ENV PATH="${HDF5_ROOT}/bin:${PATH}"

# Update bashrc file
RUN echo "source scl_source enable devtoolset-11" >> /opt/bashrc
