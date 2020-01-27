FROM gitpod/workspace-full-vnc
USER root
ARG SHELLCHECK_VERSION=stable
ARG SHELLCHECK_FORMAT=gcc
RUN wget "https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
RUN tar -xvf shellcheck-"${SHELLCHECK_VERSION}".linux.x86_64.tar.xz
RUN cp shellcheck-"${SHELLCHECK_VERSION}"/shellcheck /usr/bin/
RUN shellcheck --version
RUN echo 'export PATH="/workspace/network/bin:$PATH"' >> ~/.bashrc
CMD ["bash"]
