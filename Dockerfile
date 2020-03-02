# The toolchain for copy, chroot & resize Raspberry Pi images

# Copyright 2018-2020 Artem Smirnov @urpylka
# Copyright 2019 Alexey Rogachevskiy @sfalexrog

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM hypriot/qemu-register as qemu

FROM debian

# Coping compiled binaries to your image
COPY --from=qemu /qemu-arm /qemu-arm
COPY --from=qemu /qemu-aarch64 /qemu-aarch64
COPY --from=qemu /qemu-ppc64le /qemu-ppc64le
COPY --from=qemu /qemu-riscv64 /qemu-riscv64

# Coping & executing script for registering qemu in the kernel
COPY --from=qemu /register.sh /register.sh
# CMD ["/register.sh", "--reset"]

ENV DEBIAN_FRONTEND 'noninteractive'
ENV LANG 'C.UTF-8'
ENV LC_ALL 'C.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git \
    unzip wget \
    parted gawk lsof udev \
    apt-utils ca-certificates \
    && apt-get clean

COPY ./img-resize /usr/sbin/
COPY ./img-chroot /usr/sbin/

WORKDIR /mnt
CMD ["/register.sh", "--reset"]
