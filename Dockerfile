FROM golang:1.9.1

RUN apt-get update -y && \
  apt-get install -y build-essential curl git libncurses5-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -ms /bin/bash -d /vim-go vim-go
USER vim-go
WORKDIR /vim-go
COPY . /vim-go/
RUN make install

ENTRYPOINT ["make"]
