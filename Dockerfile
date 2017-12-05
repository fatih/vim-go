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

ENTRYPOINT ["make"]
