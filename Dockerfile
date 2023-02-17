FROM registry-edge.cosmoplat.com/d3osdev/shell-operator:v1.0.0-beta.5-alpine3.13

ENV  ANSIBLE_ROLES_PATH /d3os/installer/roles
WORKDIR /d3os
ADD controller/* /hooks/d3os/

ADD roles /d3os/installer/roles
ADD env /d3os/results/env
ADD playbooks /d3os/playbooks

#RUN chown d3os:d3os -R /d3os /hooks/d3os
USER d3os
