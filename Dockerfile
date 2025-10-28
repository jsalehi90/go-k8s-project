FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod tidy && \
    go build -o main .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/main .

EXPOSE 80

CMD ["./main"]