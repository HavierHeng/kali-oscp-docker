# Kali OSCP Docker Image

## Description 
Being mostly unsatisfied by how minimal the base Kali Linux Docker image is, this is a modified Dockerfile that takes the original rolling docker image and installs the full GUI desktop metapackage of Kali Linux. 

It also adds some development tools of my personal choice such as neovim with a base kickstart.nvim configuration and tmux for multiplexing, and ranger for terminal file navigation, fd and ripgrep for searching files. You may remove this from the `Dockerfile` if its bloatware to you.

For OSCP purposes, OpenVPN is available, and an `.ovpn` file can be passed into the container via the mounted directory at `./oscp`.

This allows to freeze a layer with a full system. This system is higher overhead than a headless kali box, but should allow for more flexibility in its usage, especially for some GUI only tools like Burp Suite.

Also given the nature of the hacking tools, this docker container has a lot of permissions defined in the `docker-compose.yaml`, its good to read through and acknowledge what is given:
- `cap_add: [NET_ADMIN, NET_RAW, SYS_PTRACE]` allow for OpenVPN, raw packets, and debugging
- `devices: /dev/net/tun` provides OpenVPN tunnel for lab 
- `security_opt: seccomp=unconfined` allows for syscalls for pentesting tools
- `volumes: ./oscp:/oscp` for persisting data from container, but also to pass data between host and container. This may be used for flags or passing in `.ovpn` files. Do not put files here that might pose a security risk to your host.
- `ports: ["2222:22", "6080:6080"]` maps SSH and noVNC to host ports 2222 and 6080 from an internal container port of 22 and 6080.

A personal recommendation for this docker container is to run it on your own server, and then VPN and connect into it from anywhere from a thin client. 

## Setup

> Warning: Kali Linux Desktop is large. Expect a few GB of space free. With docker's default configuration, it will try to put the docker images into `/var/lib/docker` which is on your root partition. If this is not desired, you have to stop docker and modiy its `/etc/docker/daemon.json` to point to another "data-root" The instructions for these can be found in the section "If Root Partition runs out of space".

Install docker compose (apt-based e.g Debian and Ubuntu): `sudo apt update && sudo apt install docker-compose-plugin`

Build and run container: `docker-compose up -d`

Default login password for ssh and novnc: `P@ssw0rd`

Set up OSCP lab `.ovpn` connection
- Copy `.ovpn` file to `./oscp`
- In container: `openvpn --config /oscp/lab.ovpn`
- Verify connectivity: `ping <lab_ip>`

Check resources on host
- `htop` and see if the current 8GB, 4 CPU split is too much for host to handle. Reduce in docker-compose.yaml if necessary.

Shutdown (if not in-use): `docker-compose down`

Change password within container
- `passwd` for SSH password/main account
- `vncpasswd` for VNC such as noVNC or tightVNC

## Connection methods - Headless and GUI and web server (if any)
- CLI via Docker: `docker exec -it kali-oscp /bin/bash` - for headless mode
- SSH: `ssh root@<host_ip> -p 2222` with password `P@ssw0rd` - for headless mode. Port is 2222 just to prevent clashing with existing ssh port if host has sshd on.
- noVNC via web browser: `http://<host_ip>:6080/vnc.html` with password `P@ssw0rd` - for use with GUI only tools
- Web server: Port 8000 on host links to port 8080 in container - e.g `python -m http.server`

## Personal Modifications for higher-end devices

If your device happens to have Nvidia hardware and allows for CUDA accelerated containers - good! You can pass the GPU access into the container to run GPU accelerated tools like Hashcat.
- Install NVIDIA Container Toolkit and restart docker on Host
- Check nvidia drivers with `nvidia-smi` on Host
- Optional (if developing GPU based tools): install CUDA SDK within the container

Add to `docker-compose.yml` NVIDIA runtime and GPU access:
```yaml
kali-oscp:
  # ... other configs ...
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
```

RAM and CPU cores can be modified via the docker-compose.yaml. CPU and RAM overhead is somewhat high due to software rendering in noVNC.

Within `supervisord.conf`, VNC resolution for noVNC can be increased to higher resolutions e.g 1920x1080 for more comfortable viewing.

Rebuild the docker container `docker-compose up -d --build`

## If Root partition runs out of space: Migrating Docker folder

Docker by default uses the Root partition at `/var/lib/docker`, which can be a problem given how big this docker image can get. You might face issues with root partition running out of space in a split home setup.
1) Debug Free Space: `df -h /` and `df -h /home` 
2) Stop docker: `sudo systemctl stop docker` and `sudo systemctl stop docker.socket`
3) Make new directory: `mkdir -p /home/<user>/docker` and `sudo chown <user>:<user> /home/<user>/docker`
4) Backup docker: `sudo rsync -a /var/lib/docker /home/<user>/docker`
5) Create a new Docker Daemon configuration to specify new data root: `sudo mkdir -p /etc/docker` and `sudo nano /etc/docker/daemon.json`
```json
{
  "data-root": "/home/<user>/docker"
}
```
6) Clean up old docker path to free up root partition: `sudo rm -rf /var/lib/docker`
7) Restart docker: `sudo systemctl start docker` and `sudo systemctl enable docker`
8) Sanity check for new directory: `docker info --format '{{.DockerRootDir}}'`



