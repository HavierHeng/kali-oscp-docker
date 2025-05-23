FROM kalilinux/kali-rolling:latest

LABEL maintainer="Javier Heng <heng.tzejian.javier@gmail.com>"
LABEL description="Kali Linux for OSCP with noVNC, OpenVPN, and Dev Environment"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Bootstrap HTTP certificates before HTTPS
RUN apt-get update && apt-get install -y ca-certificates apt-transport-https

# Install Kali Linux Desktop Full Utilities
RUN apt-get update && apt-get install -y kali-linux-default

# Install OSCP tools, OpenVPN, SSH, noVNC, dev tools, and utilities
# TODO: These are my preference - change to your development tools
RUN apt-get update && apt-get install -y \
    openvpn \
    curl \
    nano \
    git \
    fd-find \
    ripgrep \
    fzf \
    python3-pip \
    net-tools \
    iputils-ping \
    openssh-server \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    supervisor \
    gobuster \
    seclists \
    crackmapexec \
    bloodhound \
    neo4j \
    impacket-scripts \
    wfuzz \
    dnsutils \
    tmux \
    rlwrap \
    kitty \
    neovim \
    nodejs \
    npm \
    make \
    gcc \
    ripgrep \
    unzip \
    xclip \
    ranger \
    build-essential \
    gdb \
    valgrind \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install JetBrainsMono Nerd font
RUN curl -fLo /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && \
    mkdir -p /usr/local/share/fonts && \
    unzip /tmp/JetBrainsMono.zip -d /usr/local/share/fonts/ && \
    fc-cache -fv && \
    rm /tmp/JetBrainsMono.zip

# Fix sources.list to HTTPS
# Done after the build stage as HTTPS is prone to breaking
RUN echo "deb https://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src https://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list

# Set up neovim with kickstart.nvim
RUN git clone https://github.com/nvim-lua/kickstart.nvim.git /root/.config/nvim 
RUN sudo apt update && sudo apt install -y python3-pynvim
RUN nvim --headless "+Lazy! sync" +qa 

# Set up VNC and noVNC
ENV VNC_PASSWORD=P@ssw0rd
RUN mkdir -p /root/.vnc && \
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    touch /root/.Xauthority && \
    echo "xfce4-session" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "root:P@ssw0rd" | chpasswd

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose container ports (VNC: 5901, noVNC: 6080, SSH: 22, web server: 8080) - solely for documentation
EXPOSE 5901 6080 22 8080

# Set working directory for OSCP files
WORKDIR /oscp

# Start services with supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
