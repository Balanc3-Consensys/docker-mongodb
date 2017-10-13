FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

FROM golang as build
RUN curl https://glide.sh/get | sh
RUN git clone https://github.com/dcu/mongodb_exporter.git $GOPATH/src/github.com/dcu/mongodb_exporter
RUN cd $GOPATH/src/github.com/dcu/mongodb_exporter && \
    make build
RUN mv $GOPATH/src/github.com/dcu/mongodb_exporter/mongodb_exporter /mongodb_exporter

FROM base as final
COPY --from=build /mongodb_exporter /usr/local/bin/mongodb_exporter

#MongoDB
RUN wget -O - https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.4.9.tgz | tar zx
RUN mv mongodb* mongodb

ENV PATH $PATH:/mongodb/bin

#Add runit services
ADD sv /etc/service 

