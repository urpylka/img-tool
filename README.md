# img-tool

The tool-bundle to execute commands (amd64, armhf &amp; arm64) &amp; resize the Raspberry Pi images. Due to docker scripts it can work on Linux, macOS & etc.

1. Now it only works with **Raspbian OS images** (due to filesystem partition scheme). Plans to make a more universal version (w arch-configs) for **Orange Pi**, **Nano Pi** and etc.

2. All plans of development you can find at [Github Projects](https://github.com/urpylka/img-tool/projects/1).

3. You can use it manualy or by scripts (example of using at [`img-builder`](https://github.com/urpylka/img-builder) project). Also this project is using in [COEX CLOVER](https://github.com/copterexpress/clover).

## API v0.7.1

For easy using the docker image you need to make alias:

```bash
alias img-tool='docker run --privileged -it --rm -v $(pwd):/mnt urpylka/img-tool:0.7.1 img-tool'
```

* You can add this command to `~/.bash_profile` or `~/.bashrc` to make it permanent.
* For work you need to mount directory from root system to docker container `-v $(pwd):/mnt`. After that `IMG_PATH`, `SCRIPT`, `MOVE_FILES` will have been used from this directory. But `IMG_PATH` can be a block device (like your USB flash drive). For that you need to mount host device `-v /dev/disk1:/dev/disk1` It didn't work at `macOS`, because that docker used Hyperkit ([who can't work with USB devices](https://github.com/moby/hyperkit/issues/149)).
* Also you need to use `--privileged` flag for work with this docker image. (Why we need `--privileged` flag? Seems it needs for chrooting and losetup cannot be working with `/dev/loop*`).

The docker image consists **img-tool** script. It can be used for:

1. Executing something in the images

    ```bash
    img-tool <IMG_PATH> exec <SCRIPT> [...]
    ```

    Where `[...]` is arguments for `<SCRIPT>`. `<SCRIPT>` is locating on the host (and copying to target image until execution is finished). Leave `img-tool <IMAGE> exec` without any arguments for enter to `/bin/bash` at the target image.

2. Coping to the images

    ```bash
    img-tool <IMG_PATH> copy <MOVE_FILES> <MOVE_TO>
    ```

3. Changing size (minimize & maximize) of the images **(works only with image files)**

    ```bash
    img-tool <IMG_PATH> size [NEW_SIZE]
    ```

    If you leave `NEW_SIZE` argument empty, program return posible minimum size and other information about the image. It works by **resize2fs** and maybe more than actually (for take minimum size minimize image a few times (usually 3-4 times)). It may also work poorly if used 1K, 2K block in FS (more on [man7.org](http://man7.org/linux/man-pages/man8/resize2fs.8.html)).

    For automatic minimize the image use:

    ```bash
    img-tool <IMG_PATH> size $(img-tool <IMG_PATH> size | grep "IMG_MIN_SIZE" | cut -b 15-)
    ```

4. The script also consists additional functions who is needed for builds: `get_repo_ver`, `get_repo_url`, `get_repo_name`, `rich_echo`, `travis_retry`.

    For use it, source it (inside the container):

    ```bash
    source img-tool
    ```

    > You can see how it works at [`img-builder`](https://github.com/urpylka/img-builder) project.

## Build own version

```bash
docker build -t urpylka/img-tool:local .

# Alias for ease using
alias img-tool='docker run --privileged -it --rm -v $(pwd):/mnt urpylka/img-tool:local img-tool'
```

### Requirements in the Docker image

Requirement | Description
--- | ---
gawk=1:4.2.1+dfsg-1 | GNU Awk 4.2.1, API: 2.0 (GNU MPFR 4.0.2, GNU MP 6.1.2)
parted=3.2-25 | parted (GNU parted) 3.2
util-linux=2.33.1-0.1 | losetup, fdisk, fsck
truncate | (GNU coreutils) 8.30
chroot | (GNU coreutils) 8.30
resize2fs | 1.44.5 (15-Dec-2018)
curl | 7.64.0

## License

Copyright 2018-2020 Artem Smirnov, Alexey Rogachevskiy, Arthur Golubtsov

Licensed under the Apache License, Version 2.0
