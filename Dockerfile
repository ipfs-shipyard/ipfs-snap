# An image that can build go-ipfs as a snap.
FROM snapcore/snapcraft:stable
LABEL maintainer="Oli Evans <oli@protocol.ai>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    g++ \
    gcc \
    libc6-dev \
    make \
    wget

ENV GOLANG_VERSION 1.14.4
ENV PATH /usr/local/go/bin:$PATH
RUN url="https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
    wget -O go.tgz "$url" --progress=dot:giga; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version
 
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

WORKDIR $GOPATH

ARG GIT_COMMIT=unspecified
LABEL git_commit=$GIT_COMMIT
