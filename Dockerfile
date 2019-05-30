FROM golang AS build
WORKDIR /root/
COPY sample.go .
RUN GO111MODULE=on CGO_ENABLED=0 go build -o app sample.go

FROM golang:alpine
WORKDIR /root/
COPY --from=build /root/app .
EXPOSE 80
CMD ["./app"]