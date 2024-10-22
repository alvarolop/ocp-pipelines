FROM registry.redhat.io/ubi8/ubi

USER 0

COPY ./kustomize /usr/bin/kustomize

RUN dnf upgrade -y && dnf install -y jq telnet && dnf clean all

# Set the HOME directory to a writable path
ENV HOME=/tmp

USER 100
