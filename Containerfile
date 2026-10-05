FROM ghcr.io/linuxserver/webtop:fedora-mate

COPY root/ /

# Remove unwanted packages
RUN dnf remove -y \
      chromium

# Install wanted packages
RUN dnf install -y \
      code \
      firefox \
      jq \
      libreoffice \
      virt-viewer

# Install Joplin
RUN cd /usr/local/src && \
    curl -Lo joplin.AppImage $(curl -s https://api.github.com/repos/laurent22/joplin/releases/latest | jq -r '.assets[] | select(.name | endswith("AppImage")) | .browser_download_url') && \
    chmod +x joplin.AppImage && \
    ./joplin.AppImage --appimage-extract && \
    rm joplin.AppImage && \
    mv squashfs-root joplin && \
    ln -s $(pwd)/joplin/joplin /usr/local/bin/joplin

# Install kubectl and virtctl
RUN export VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt) && \
    curl -Lo /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64 && \
    chmod +x /usr/local/bin/virtctl

# Rename user
RUN for file in /etc/passwd /etc/group /etc/shadow; do \
        sed -i 's/abc/user/g' "$file"; \
    done && \
    find /etc/s6-overlay/s6-rc.d -type f -name 'run' -exec sed -i 's/abc/user/g' {} \; && \
    usermod -d /home/user user
