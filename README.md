# img-tool

Utilities for execute commands (amd64 &amp; armhf) &amp; resize the file-images. Due to docker scripts can work on Ubuntu, macOS & etc.

Now it only works with **Raspbian OS images** due to filesystem partition scheme. Plans to make a more universal version (w arch-configs) for **Orange Pi**, **Nano Pi** and etc. Project used in [COEX CLEVER](https://github.com/copterexpress/clever).

## API v0.4

Image consist two scripts:

1. **img-chroot** – for execute something in the file-image and copy to the file-image
2. **img-resize** – for change size of the image to minimize & maximize

* For work you need to mount directory from root system to docker-container: use `-v $(pwd):/mnt`
* Also you can transfer variable to docker-container: use `-e NAME="VALUE"`

### Execute in image or copy files to image

```bash
docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt urpylka/img-tool:v0.4 img-chroot <IMAGE> [ exec <SCRIPT> [...] | copy <MOVE_FILES> <MOVE_TO> ]
```

Where `[...]` is arguments for `<SCRIPT>`. `<SCRIPT>` is locating on the host (and copying to target image until execution is finished). Leave `img-chroot <IMAGE>` without any argument for enter to `/bin/bash` on the target image.

### Resize image (minimize & maximize)

```bash
docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt urpylka/img-tool:v0.4 img-resize <IMAGE> [NEW_SIZE]
```

> If you leave `NEW_SIZE` parameter empty, program return posible minimum size. It works by **resize2fs** and maybe more than actually (for take minimum size minimize image a few times). It may also work poorly if used 1K, 2K block in FS (more on [man7.org](http://man7.org/linux/man-pages/man8/resize2fs.8.html)).

### Requirements

Requirement | Description
--- | ---
gawk=1:4.2.1+dfsg-1 | GNU Awk 4.2.1, API: 2.0 (GNU MPFR 4.0.2, GNU MP 6.1.2)
parted=3.2-25 | parted (GNU parted) 3.2
util-linux=2.33.1-0.1 | losetup from util-linux 2.33.1

## Build own version

```bash
docker build -t img-tool:local .

# Alias for ease of use
alias img='docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt img-tool:local'
```

## Other

Install the shortcut on macOS:

```bash
echo "alias img='docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt urpylka/img-tool:v0.4'" >> ~/.bash_profile
```

Use the shortcut:

```bash
img img-resize <IMAGE> [NEW_SIZE]
```

```bash
img img-chroot <IMAGE> [ exec <SCRIPT> [...] | copy <MOVE_FILE> <MOVE_TO> ]
```

## License

Copyright 2018-2020 Artem Smirnov, Alexey Rogachevskiy, Arthur Golubtsov

Licensed under the Apache License, Version 2.0
