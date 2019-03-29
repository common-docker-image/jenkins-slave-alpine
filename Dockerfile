FROM prong/openjdk:8-jdk-alpine
MAINTAINER visionken <visionken2017@qq.com>

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN addgroup -g ${gid} ${group} \
    && adduser -h ${JENKINS_AGENT_HOME} -u ${uid} -G ${group} -s /bin/bash -D ${user} \
    && passwd -u jenkins

# setup SSH server and git
RUN apk --update add --no-cache openssh git \
  && rm -rf /var/cache/apk/*

RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' \
  && mkdir /var/run/sshd \
  && git config --system http.sslVerify false

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
