FROM golang:1.11 AS builder

ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

# Install mingw, arm32 and arm64 compilers
RUN echo "$TARGETPLATFORM"
RUN apt-get update 
RUN apt-get install -y mingw-w64
RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then apt-get install -y g++-arm-linux-gnueabihf gcc-arm-linux-gnueabihf  ; fi
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then apt-get install -y g++-aarch64-linux-gnu gcc-aarch64-linux-gnu ; fi


WORKDIR /go/src/github.com/newrelic/newrelic-fluent-bit-output

COPY Makefile go.* *.go /go/src/github.com/newrelic/newrelic-fluent-bit-output/
COPY config/ /go/src/github.com/newrelic/newrelic-fluent-bit-output/config
COPY nrclient/ /go/src/github.com/newrelic/newrelic-fluent-bit-output/nrclient
COPY record/ /go/src/github.com/newrelic/newrelic-fluent-bit-output/record
COPY utils/ /go/src/github.com/newrelic/newrelic-fluent-bit-output/utils

ENV SOURCE docker
RUN go get github.com/fluent/fluent-bit-go/output

# Build for target platform
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then make linux-amd64 ; fi
RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then make linux-arm ; fi
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then make linux-arm64 ; fi

FROM fluent/fluent-bit:1.7.6

ARG OUTPUT_FILE="amd64"
# RUN if [ $TARGETPLATFORM == "linux/amd64" ] ; then OUTPUT_FILE="amd64" ; fi
# RUN if [ $TARGETPLATFORM == "linux/arm/v7" ] ; then OUTPUT_FILE="arm" ; fi
# RUN if [ $TARGETPLATFORM == "linux/arm64" ] ; then OUTPUT_FILE="arm64" ; fi

COPY --from=builder /go/src/github.com/newrelic/newrelic-fluent-bit-output/out_newrelic-linux-*-*.so /fluent-bit/bin/out_newrelic.so
COPY *.conf /fluent-bit/etc/

CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf", "-e", "/fluent-bit/bin/out_newrelic.so"]
