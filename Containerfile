ARG EE_BASE_IMAGE=quay.io/ansible/ansible-runner:latest
ARG EE_BUILDER_IMAGE=quay.io/ansible/ansible-builder:latest

FROM $EE_BASE_IMAGE as galaxy
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=
USER root

ADD _build /build
WORKDIR /build

RUN ansible-galaxy role install -r requirements.yml --roles-path /usr/share/ansible/roles
RUN ansible-galaxy collection install $ANSIBLE_GALAXY_CLI_COLLECTION_OPTS -r requirements.yml --collections-path /usr/share/ansible/collections

FROM $EE_BUILDER_IMAGE as builder

COPY --from=galaxy /usr/share/ansible /usr/share/ansible

ADD _build/bindep.txt bindep.txt
RUN ansible-builder introspect --sanitize --user-bindep=bindep.txt --write-bindep=/tmp/src/bindep.txt --write-pip=/tmp/src/requirements.txt
RUN assemble

FROM $EE_BASE_IMAGE
USER root

RUN yum install -y sudo
COPY --from=galaxy /usr/share/ansible /usr/share/ansible

COPY --from=builder /output/ /output/
RUN /output/install-from-bindep && rm -rf /output/wheels
COPY --from=quay.io/project-receptor/receptor:1.0.0a2 /usr/bin/receptor /usr/bin/receptor
RUN mkdir -p /var/run/receptor
ADD run.sh /run.sh
CMD /run.sh
#USER 1000
RUN git lfs install

## ndap-playbooks/roles/common/tasks/package.yml
RUN yum install -y java-1.8.0-openjdk-devel
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
# java-1.8.0-openjdk-devel
# gcc
# python-devel
# python-pip
RUN yum install -y zip
RUN yum install -y unzip
RUN yum install -y openssh
RUN yum install -y openssl
RUN yum install -y openssl-devel
RUN yum install -y swig
RUN yum install -y snappy
RUN yum install -y snappy-devel
RUN yum install -y libselinux-python
RUN yum install -y mysql-connector-python
RUN yum install -y libselinux-python
# RUN yum install -y bigtop-utils
RUN yum install -y m2crypto
RUN yum install -y python-httplib2
COPY _build/java/* /usr/share/java/
# RUN yum install -y mariadb-java-client
RUN curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
RUN yum install -y MariaDB-client
RUN yum install -y MySQL-python
RUN yum install -y python-netaddr
RUN python3 -m pip install PyMySQL

RUN mkdir -p /root/.ssh/
COPY _build/ssh/* /root/.ssh/
RUN sed -i'' -r -e "/#   StrictHostKeyChecking ask/a\StrictHostKeyChecking no" /etc/ssh/ssh_config
