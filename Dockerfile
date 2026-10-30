FROM ubuntu:22.04

# Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    ubuntu-keyring \
    build-essential \
    cmake \
    git \
    python3-pip \
    python3-dev \
    screen \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Add ROS 2 GPG key and repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS 2 Humble and dependencies
RUN apt-get update && apt-get install -y \
    ros-humble-desktop \
    ros-humble-controller-manager \
    ros-humble-joint-trajectory-controller \
    ros-humble-robot-state-publisher \
    ros-humble-dynamixel-sdk \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-ros2controlcli \
    ros-humble-realtime-tools \
    ros-humble-joint-state-broadcaster \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /ws

# Copy project
COPY . /ws/

# Source ROS setup
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

# Skip building during Docker build (build on container start if needed)

# Setup entrypoint
RUN echo '#!/bin/bash\n\
source /opt/ros/humble/setup.bash\n\
if [ -d "/ws/install" ]; then\n\
  source /ws/install/setup.bash 2>/dev/null || true\n\
fi\n\
exec "$@"' > /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/bash"]
