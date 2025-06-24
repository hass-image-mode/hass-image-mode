FROM quay.io/fedora/fedora-bootc:42
RUN cat /deps/ansible.txt | xargs dnf -y install

COPY ./containers-systemd/* /usr/share/containers/systemd/
RUN mkdir -p /var/home-assistant/config && \
    firewall-offline-cmd --add-port=8123/tcp
