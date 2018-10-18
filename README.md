# img-tool

Utilities for execute commands (amd64 &amp; armhf) &amp; resize the file-images. Due to docker scripts can work on Ubuntu, macOS & etc.

## API v0.3

Image consist two scripts:

1. **img-chroot** – for execute something in the file-image and copy to the file-image
2. **img-resize** – for change size of the image to minimize & maximize

* For work you need to mount directory from root system to docker-container: use `-v $(pwd):/mnt`
* Also you can transfer variable to docker-container: use `-e NAME="VALUE"`

### Execute in image

```bash
docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt smirart/img-tool:v0.3 img-chroot <IMAGE> [ exec <SCRIPT> [...] | copy <MOVE_FILE> <MOVE_TO> ]
```

### Resize image

```bash
docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/mnt smirart/img-tool:v0.3 img-resize <IMAGE> [ min <FREE_SPACE> | max <FREE_SPACE> ]
```

## License

Copyright 2018 Artem B. Smirnov

Licensed under the Apache License, Version 2.0