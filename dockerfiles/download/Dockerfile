FROM registry.redhat.io/ubi8/ubi

USER 0

RUN dnf upgrade -y && dnf install -y jq telnet && dnf clean all

USER 100
