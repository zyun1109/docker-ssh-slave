# The MIT License
#
#  Copyright (c) 2015, CloudBees, Inc.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

FROM openjdk:7-jdk
LABEL MAINTAINER="Andy Boyett <andy.boyett@gmail.com>"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}
ARG BOUNCYCASTLE_VERSION=1.47
ARG JAVA_MAJOR_VERSION=7

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

# setup SSH server
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        openssh-server git \
    && apt-get clean
RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd

# install sbt
RUN wget https://raw.githubusercontent.com/paulp/sbt-extras/master/sbt -O /usr/local/bin/sbt && chmod +x /usr/local/bin/sbt

ENV JDK_HOME=/usr/lib/jvm/java-7-openjdk-amd64
# install bouncycastle
RUN wget http://central.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/${BOUNCYCASTLE_VERSION}/bcpkix-jdk15on-${BOUNCYCASTLE_VERSION}.jar http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/${BOUNCYCASTLE_VERSION}/bcprov-jdk15on-${BOUNCYCASTLE_VERSION}.jar -P $JDK_HOME/jre/lib/ext/ && echo "security.provider.11=org.bouncycastle.jce.provider.BouncyCastleProvider" >> $JDK_HOME/jre/lib/security/java.security

# backport git for subtree fix: https://github.com/git/git/commit/933cfeb
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && apt-get update \
    && apt-get install -y -t jessie-backports git

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
