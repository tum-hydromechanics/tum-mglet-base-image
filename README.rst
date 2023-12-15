###############################
Fortran compilation tools image
###############################

This image contains recent versions of Intel compilers, MPI and HDF5 along with
basic build tools (CMake, Ninja). This image can then be used to compile
Fortran applications that depend on MPI and HDF5.

Two images for different workflows are built:

1. ``intel-impi-image``: Intel Compilers and Intel MPI
2. ``gnu-openmpi-image``: GNU Compilers and OpenMPI

Images are automatically build with Github Actions and are published at the
Github container registry.

If you want to build the images yourself locally, the commands are::

    docker build --target intel-impi-image -t intel-impi-image:latest .
    docker build --target gnu-ompi-image -t gnu-ompi-image:latest .
    
    
Helpful commands are::

    docker run -dit intel-impi-image
    docker run -dit gnu-openmpi-image
    
    
docker ps

CONTAINER ID   IMAGE              COMMAND       CREATED          STATUS          PORTS     NAMES
22c87fefb12c   gnu-ompi-image     "/bin/bash"   19 minutes ago   Up 19 minutes             tender_rhodes
6d55b5ae2986   intel-impi-image   "/bin/bash"   21 minutes ago   Up 21 minutes             romantic_hawking

docker exec -it 22c87fefb12c bash

[exit]

docker stop 22c87fefb12c
docker stop 6d55b5ae2986





