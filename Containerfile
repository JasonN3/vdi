FROM ghcr.io/linuxserver/webtop:fedora-mate@sha256:37c7c611b00158a5847eed0504e4b8405103e403d2f5f5696e23c987e3de1eed AS BASE

COPY root/ /

# Remove unwanted packages
RUN dnf remove -y \
      chromium && \
    dnf clean all

FROM BASE AS CODE

# Install VSCode
RUN dnf install -y code && \
    dnf clean all

FROM CODE AS FIREFOX
RUN dnf install -y firefox && \
    dnf clean all

FROM FIREFOX AS LIBREOFFICE
RUN dnf install -y libreoffice && \
    dnf clean all

FROM LIBREOFFICE AS TOOLS
RUN dnf install -y \
      jq \
      virt-viewer \
      opentofu && \
    dnf clean all

FROM TOOLS AS JOPLIN

# Install Joplin
RUN cd /usr/local/src && \
    curl -Lo joplin.AppImage $(curl -s https://api.github.com/repos/laurent22/joplin/releases/latest | jq -r '.assets[] | select(.name | endswith("AppImage")) | .browser_download_url') && \
    chmod +x joplin.AppImage && \
    ./joplin.AppImage --appimage-extract && \
    rm joplin.AppImage && \
    mv squashfs-root joplin && \
    ln -s $(pwd)/joplin/AppRun /usr/local/bin/joplin

FROM JOPLIN AS FREECAD

RUN cd /usr/local/src && \
    curl -Lo freecad.AppImage $(curl -s https://api.github.com/repos/FreeCAD/FreeCAD/releases/latest | jq -r '.assets[] | select((.name | endswith("AppImage")) and (.name | contains("x86_64"))) | .browser_download_url') && \
    chmod +x freecad.AppImage && \
    ./freecad.AppImage --appimage-extract && \
    rm freecad.AppImage && \
    mv squashfs-root freecad && \
    ln -s $(pwd)/freecad/AppRun /usr/local/bin/freecad

FROM FREECAD AS KUBE

# Install kubectl and virtctl
RUN export VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt) && \
    curl -Lo /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64 && \
    chmod +x /usr/local/bin/virtctl

FROM KUBE AS USER
# Rename user
RUN for file in /etc/passwd /etc/group /etc/shadow; do \
        sed -i 's/abc/user/g' "$file"; \
    done && \
    find /etc/s6-overlay/s6-rc.d -type f -name 'run' -exec sed -i 's/abc/user/g' {} \; && \
    usermod -d /home/user user

ENV HOME=/home/user \
    START_DOCKER=false
