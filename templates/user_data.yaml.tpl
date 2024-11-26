#cloud-config
# Wait for the disk to be attached.
bootcmd:
  # https://github.com/canonical/cloud-init/issues/3386
  - |
    disk_to_wait_for="/dev/${additional_disk_name}"

    # Timeout in seconds
    timeout=600 # 10 minutes

    # Check every `interval` seconds
    interval=5

    elapsed=0
    while [ ! -e "$disk_to_wait_for" ]; do
        sleep "$interval"
        elapsed=$((elapsed + interval))

        if [ "$elapsed" -ge "$timeout" ]; then
            echo "Timeout reached. Disk not found: $disk_to_wait_for"
            exit 1
        fi
    done

    echo "Disk found: $disk_to_wait_for"

disk_setup:
  /dev/${additional_disk_name}:
    table_type: 'mbr'
    layout: true
    overwrite: false

fs_setup:
  - label: data
    filesystem: ext4
    device: /dev/${additional_disk_name}
    partition: auto
    overwrite: false

growpart:
  devices: [/, /dev/${additional_disk_name}]
  mode: auto

mounts:
  - [${additional_disk_name}, /data, "auto", "defaults,nofail", "0", "0"]

apt_pipelining: os
apt:
  sources:
    caddy:
      source: "deb [signed-by=$KEY_FILE] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main"
      keyid: ABA1F9B8875A6661
    docker:
      source: "deb [arch=amd64 signed-by=$KEY_FILE] https://download.docker.com/linux/ubuntu $RELEASE stable"
      keyid: 7EA0A9C3F273FCD8
    nvidia-container-toolkit:
      source: "deb [signed-by=$KEY_FILE] https://nvidia.github.io/libnvidia-container/stable/deb/$(ARCH) /"
      keyid: DDCAE044F796ECB0

package_update: true
package_upgrade: true
packages:
  - caddy
  - vim-tiny
  - git
  - wget 
  - curl
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin
  - nvidia-driver-550-server
  - nvidia-utils-550-server
  - nvidia-docker2

users:
  - default

write_files:
  - path: /etc/caddy/Caddyfile
    permissions: '0644'
    content: |
      https:// {
        tls internal {
          on_demand
        }

        handle /whisper* {
          reverse_proxy localhost:7860
        }
        handle {
          reverse_proxy localhost:3000
        }
      }
  - path: /etc/systemd/system/whisper.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Whisper-UI Docker Compose Service
      After=network.target docker.service
      Requires=docker.service

      [Service]
      Type=oneshot
      RemainAfterExit=true
      User=ubuntu
      Group=ubuntu
      WorkingDirectory=/data/services/whisper

      ExecStart=/usr/bin/docker compose -f docker-compose.yaml -f docker-compose.path.yaml up -d
      ExecStop=/usr/bin/docker compose down

      # Restart options
      Restart=on-failure
      RestartSec=10

      # Environment for GPU support (NVIDIA runtime)
      Environment="NVIDIA_VISIBLE_DEVICES=all"
      Environment="NVIDIA_DRIVER_CAPABILITIES=all"

      [Install]
      WantedBy=multi-user.target
  - path: /etc/systemd/system/open-webui.service
    permissions: '0644'
    content: |
      [Unit]
      Description=OpenWeb-UI Docker Compose Service
      After=network.target docker.service
      Requires=docker.service

      [Service]
      Type=oneshot
      RemainAfterExit=true
      User=ubuntu
      Group=ubuntu
      WorkingDirectory=/data/services/open-webui

      # Ensure Docker Compose uses GPU
      ExecStart=/usr/bin/docker compose -f docker-compose.yaml -f docker-compose.gpu.yaml up -d
      ExecStop=/usr/bin/docker compose down

      # Restart options
      Restart=on-failure
      RestartSec=10

      # Environment for GPU support (NVIDIA runtime)
      Environment="NVIDIA_VISIBLE_DEVICES=all"
      Environment="NVIDIA_DRIVER_CAPABILITIES=all"

      [Install]
      WantedBy=multi-user.target
  - path: /tmp/install.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash

      # Remap docker to external disk
      systemctl stop docker
      mv /var/lib/docker /data/docker
      ln -fs /data/docker /var/lib/docker

      # Add user ubuntu to the group docker
      usermod -aG docker ubuntu
      usermod -aG video ubuntu

      echo "Enable Docker"
      systemctl enable docker 
      systemctl restart docker

      mkdir /data/services/
      git clone https://github.com/open-webui/open-webui.git /data/services/open-webui
      cp /data/services/open-webui/.env.example /data/services/open-webui/.env
      
      git clone https://github.com/jhj0517/Whisper-WebUI.git /data/services/whisper
      echo "services:\n  app:\n    environment:\n      - 'GRADIO_ROOT_PATH=/whisper'\n" > /data/services/whisper/docker-compose.path.yaml

      chown -R ubuntu:ubuntu /data/services

      systemctl daemon-reload
      systemctl enable open-webui
      systemctl enable whisper
      systemctl enable caddy
      reboot

runcmd:
  - [ sh, "/tmp/install.sh" ]
