FROM ros:humble-desktop

# Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    colcon-common-extensions \
    ros-humble-controller-manager \
    ros-humble-joint-trajectory-controller \
    ros-humble-robot-state-publisher \
    build-essential \
    cmake \
    screen \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /ws

# Copy project
COPY . /ws/

# Source ROS setup
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

# Build package
RUN bash -c 'source /opt/ros/humble/setup.bash && \
    colcon build --packages-select duo_joint 2>&1'

# Setup entrypoint
RUN echo '#!/bin/bash\n\
source /opt/ros/humble/setup.bash\n\
source /ws/install/setup.bash\n\
exec "$@"' > /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/bash"]
