FROM       timn/fedora-ros:f25-kinetic

# ROS_DISTRO set by fedora-ros layer

COPY fawkes-pre.rosinstall /opt/ros/

RUN dnf copr enable thofmann/planner -y
RUN dnf copr enable mloebach/ctemplate -y
RUN dnf install fast-forward ctemplate-devel net-tools -y

# Get and compile ROS pre bits
RUN /bin/bash -c "source /etc/profile && \
  mkdir -p /opt/ros/catkin_ws_${ROS_DISTRO}_fawkes_pre/src; \
  cd /opt/ros/catkin_ws_${ROS_DISTRO}_fawkes_pre; \
  wstool init -j $(nproc) src ../fawkes-pre.rosinstall; \
  rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y; \
  catkin_make_isolated --install --install-space /opt/ros/$ROS_DISTRO \
    -DCMAKE_BUILD_TYPE=$ROS_BUILD_TYPE || exit $?; \
  rm -rf *_isolated; \
  "

ADD fawkes-robotino.tar /opt/
# Get and compile Fawkes
# Use generic optimization so that the resulting image works on more platforms.
# Enable the old 2015 agent, only that has the full model of the production.
RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash && \
	cd /opt && \
	cd fawkes-robotino && \
	sed -i -e 's/CFLAGS_EXTRA  += -g/CFLAGS_EXTRA += -m64 -mtune=generic -g/g' etc/buildsys/config.mk && \
	make -j$(nproc) all gui ${VERBOSE_FLAG} CFLAGS_MTUNE_NATIVE= &&\
	find . -name '.objs_*' -prune -exec rm -rf {} \; &&\
	find . -name '.deps_*' -prune -exec rm -rf {} \;"


# Perform the following substitutions in config files:
# * general gazebo config 
#   - Fawkes Robotino path
#   - refbox host (use cluster DNS name)
#   - peer addresses (use cluster DNS names)
#   - peer send and receive ports (anticipate maximum possible set of peers)
# * per-robot host configurations
#   - Set appropriate peer address and ports (see above)
#   - replace magenta team name, robot name and number (CLIPS-agent only)
#     (the same team will not play against itself, hence set Carologistics to
#      use the same team name, and robot name and number, with both colors)
RUN /bin/bash -c "sed -i /opt/fawkes-robotino/cfg/conf.d/gazsim.yaml \
    -e 's/~\/fawkes-robotino/\/opt\/fawkes-robotino/g' \
    -e 's/refbox-host: .*$/refbox-host: refbox/' \
    -e 's/addresses: .*$/addresses: [\"refbox\", \"robot-c1\", \"robot-c2\", \"robot-c3\", \"robot-m1\", \"robot-m2\", \"robot-m3\", \"agent-c1\", \"agent-c2\", \"agent-c3\", \"agent-m1\", \"agent-m2\", \"agent-m3\"]/' \
    -e \"s/send-ports: .*$/send-ports: [4445, $(seq -s ', ' 4411 4422)]/\" \
    -e \"s/recv-ports: .*$/recv-ports: [4444, $(seq -s ', ' 4451 4462)]/\" \
    -e \"s/send-ports-crypto1: .*$/send-ports-crypto1: [4446, $(seq -s ', ' 4471 4482)]/\" \
    -e \"s/recv-ports-crypto1: .*$/recv-ports-crypto1: [4441, $(seq -s ', ' 4491 4502)]/\" \
    -e \"s/send-ports-crypto2: .*$/send-ports-crypto2: [4447, $(seq -s ', ' 4511 4522)]/\" \
    -e \"s/recv-ports-crypto2: .*$/recv-ports-crypto2: [4442, $(seq -s ', ' 4531 4542)]/\" &&\
		for i in \$(seq 1 6); do \
				sed -i /opt/fawkes-robotino/cfg/gazsim-configurations/default/host_robotino_\$i.yaml \
						-e \"s/peer-address: .*\$/peer-address: refbox/\" \
						-e \"s/peer-recv-port: .*\$/peer-recv-port: \$(expr 4410 + \$i)/\" \
						-e \"s/peer-send-port: .*\$/peer-send-port: \$(expr 4450 + \$i)/\" \
						-e \"s/cyan-recv-port: .*\$/cyan-recv-port: \$(expr 4470 + \$i)/\" \
						-e \"s/cyan-send-port: .*\$/cyan-send-port: \$(expr 4490 + \$i)/\" \
						-e \"s/magenta-recv-port: .*\$/magenta-recv-port: \$(expr 4510 + \$i)/\" \
						-e \"s/magenta-send-port: .*\$/magenta-send-port: \$(expr 4530 + \$i)/\" \
						-e \"s/team-name: Carologistics-2/team-name: CaroPlanner/g\" \
						-e \"s/team-name: Carologistics/team-name: CaroPlanner/g\" \
						-e \"s/robot-name: R-4/robot-name: R-1/g\" \
						-e \"s/robot-name: R-5/robot-name: R-2/g\" \
						-e \"s/robot-name: R-6/robot-name: R-3/g\" \
						-e \"s/robot-number: 4/robot-number: 1/g\" \
						-e \"s/robot-number: 5/robot-number: 2/g\" \
						-e \"s/robot-number: 6/robot-number: 3/g\"; \
		done  && \
    sed -i /opt/fawkes-robotino/cfg/conf.d/pddl-planner.yaml -e \"s/planner: ff/planner: dbmp/\" \
		"

RUN mkdir -p /opt/rcll-sim/
COPY run-component setup.bash localize-robot /opt/rcll-sim/

COPY dbmp/* /usr/bin/
