FROM golang:1.9.2

RUN apt-get update -y && \
  apt-get install -y build-essential curl git libncurses5-dev python3-pip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip3 install vim-vint

RUN useradd -ms /bin/bash -d /vim-go vim-go
USER vim-go

# copy the vim install scripts in and install vim before the rest so that the
# installation of vims will be cached in the image.
COPY ./scripts /vim-go/scripts
RUN /vim-go/scripts/install-vim vim-7.4
RUN /vim-go/scripts/install-vim vim-8.0
RUN /vim-go/scripts/install-vim nvim

COPY . /vim-go/
WORKDIR /vim-go

# install the Go tools; any vim choice would work, but vim-8.0 is the current
# best supported version, so use that. This needs to be done after the vim-go
# sources are copied into the image, because it depends vim-go on the source
# files.
RUN /vim-go/scripts/install-go-tools vim-8.0

ENTRYPOINT ["make"]
