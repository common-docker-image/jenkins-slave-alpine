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
RUN apk --update add --no-cache openssh git sudo \
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

# add maven support
ENV MAVEN_VERSION 3.5.2
ENV MAVEN_HOME /usr/lib/mvn
ENV PATH $MAVEN_HOME/bin:$PATH

RUN wget http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && tar -zxvf apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && rm apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && mv apache-maven-$MAVEN_VERSION /usr/lib/mvn \
  && ln -s "$MAVEN_HOME/bin/mvn" /usr/bin/mvn 

# add docker cli support
RUN curl -O https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz \
    && tar zxvf docker-17.06.2-ce.tgz \
    && cp docker/docker /usr/local/bin/ \
    && rm -rf docker docker-17.06.2-ce.tgz

# enable sudo
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY setup-sshd /usr/local/bin/setup-sshd

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
