# Home Assistant - Image Mode Setup

Repo to test how to deploy and manage Home Assistant in [Image Mode](https://docs.fedoraproject.org/en-US/bootc/getting-started/).

More about [Image Mode here](https://developers.redhat.com/products/rhel-image-mode/overview).

## Prerequisites

- System with Fedora - currently tested on 42
  - podman installed
    - `dnf -y install podman`

## Repo structure

- *containers-system* directory with [podman quadlet files](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- *config.toml* - config for generating iso file
- config

## Build bootc image

Build bootc image:

```bash
podman build -t quay.io/jwerak/fedora-bootc-hass .
```

## Deploy instance

### Libvirt deployment

Export qcow2 format:

```bash
podman pull quay.io/fedora/fedora-bootc:latest
podman pull quay.io/centos-bootc/bootc-image-builder:latest

podman run \
    --rm -it --privileged --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v ./config.toml:/config.toml \
    -v .:/output \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    --config /config.toml \
  quay.io/jwerak/fedora-bootc-hass
```

Run VM:

```bash
sudo mv ./qcow2/disk.qcow2 /var/lib/libvirt/images/fedora-bootc-home-assistant.qcow2
sudo virt-install \
    --name fedora-bootc-home-assistant \
    --memory 4096 \
    --cpu host-model \
    --vcpus 2 \
    --import --disk /var/lib/libvirt/images/fedora-bootc-home-assistant.qcow2 \
    --os-variant rhel10.0
```

### Deploy to metal

Build ISO

```bash
podman pull quay.io/fedora/fedora-bootc:latest
podman pull quay.io/centos-bootc/bootc-image-builder:latest
podman run \
    --rm -it --privileged --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v ./config.toml:/config.toml \
    -v .:/output \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type iso \
    --config /config.toml \
  quay.io/jwerak/fedora-bootc-hass
```

## Update OS

Updating the OS is simple, all you need to do is to build new container and wait for OS do update itself:

```bash
podman build --no-cache -t quay.io/jwerak/fedora-bootc-hass .
podman push quay.io/jwerak/fedora-bootc-hass
```

The update can be then manualy enforced:

```bash
bootc upgrade
bootc status
reboot
```

### Update OS without external registry

The other option is to build new container locally and update system from it.

Build image and switch to local container storage as source for updates.

```bash
podman build --no-cache -t quay.io/jwerak/fedora-bootc-hass .
bootc switch --transport containers-storage quay.io/jwerak/fedora-bootc-hass
bootc status
bootc upgrade
reboot
```

## References

- Nice [Getting Started blog](https://www.redhat.com/en/blog/image-mode-red-hat-enterprise-linux-quick-start-guide)
- How to [Build and Deploy image mode RHEL](https://developers.redhat.com/articles/2025/03/12/how-build-deploy-and-manage-image-mode-rhel#image_mode_for_rhel)
- [Fedora Getting Started with bootc](https://docs.fedoraproject.org/en-US/bootc/getting-started/)