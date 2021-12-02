# docker-os

An easy way to build operating system images using docker.

## Building an ISO

### Requirements for Building

- A linux machine
- syslinux
- podman

### Building the ISO

To compile an iso for use in qemu or writing to a physical disk, simply run the compile.sh script with root privileges.

```zsh
sudo ./compile.sh
```

### Customizing The Base Image

If you want to use a custom base docker image, you can first build your personal image with `podman build -t myos -f Dockerfile.myos .` and then you can compile it into an iso with:

```zsh
sudo IMAGE=myos ./compile.sh
```

## Prebuilt Images

There are currently no prebuilt images available. I plan on using github actions to create releases in the future.

