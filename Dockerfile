FROM alpine:latest

RUN apk add --no-cache bash curl jq bc

WORKDIR /app
COPY . /app

RUN chmod +x serphunter.sh setup/install.sh

ENTRYPOINT ["./serphunter.sh"]
CMD ["-h"]
