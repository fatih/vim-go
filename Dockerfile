FROM golang:1.9.1

RUN apt-get update -y && \
  apt-get install -y build-essential curl git libncurses5-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /vim-go

COPY . /vim-go/

ENTRYPOINT ["make"]
