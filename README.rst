Helpful commands for docker are::

    sudo chmod 666 /var/run/docker.sock (may be necessary if permission denied)
    docker images (shows available images)
    docker run -dit d4c1a4246e02
    docker ps
    

Now you should see what is running at the moment (here as example)::
    
    $ docker ps
    CONTAINER ID   IMAGE              COMMAND       CREATED          STATUS          PORTS     NAMES
    22c87fefb12c   gnu-ompi-image     "/bin/bash"   19 minutes ago   Up 19 minutes             tender_rhodes
    6d55b5ae2986   intel-impi-image   "/bin/bash"   21 minutes ago   Up 21 minutes             romantic_hawking


It is now possible to operate bash in the container::

    docker exec -it 22c87fefb12c bash
    [exit]


Stopping the runner containers::

    docker stop 22c87fefb12c
    docker stop 6d55b5ae2986


Finding the size of the provided image in ghrc.io (from https://gist.github.com/MichaelSimons/fb588539dcefd9b5fdf45ba04c302db6)::

    dockersize() { docker manifest inspect -v "$1" | jq -c 'if type == "array" then .[] else . end' |  jq -r '[ ( .Descriptor.platform | [ .os, .architecture, .variant, ."os.version" ] | del(..|nulls) | join("/") ), ( [ .SchemaV2Manifest.layers[].size ] | add ) ] | join(" ")' | numfmt --to iec --format '%.2f' --field 2 | column -t ; }
    dockersize ghcr.io/tum-hydromechanics/build-base-image:sha-2ec8b88

