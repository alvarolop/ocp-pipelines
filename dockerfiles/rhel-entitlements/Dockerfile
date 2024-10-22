FROM registry.redhat.io/ubi9/ubi

USER 0

RUN dnf upgrade -y && dnf install -y jq httpd-tools telnet && dnf clean all

USER 1000
