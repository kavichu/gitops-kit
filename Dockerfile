FROM golang:1.13.0-alpine as builder

RUN apk add git
RUN go get github.com/aws/aws-sdk-go

ADD ./secrets/main.go /app/

WORKDIR /app/

RUN go build -o secrets main.go

FROM python:3.7.4-alpine3.10

COPY --from=builder /app/secrets /usr/local/bin

RUN apk add curl openssl postgresql-client bash groff
RUN pip install awscli
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN curl -LO https://git.io/get_helm.sh
RUN chmod 700 get_helm.sh && sh ./get_helm.sh

RUN adduser dragon --uid 9000 -D -s /bin/bash

USER dragon
WORKDIR /home/dragon/

RUN mkdir /home/dragon/.kube
RUN mkdir -p /home/dragon/secrets/dev /home/dragon/secrets/stg /home/dragon/secrets/prd
