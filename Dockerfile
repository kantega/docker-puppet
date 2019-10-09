ARG PUPPETSERVER_VERSION
FROM puppet/puppetserver:$PUPPETSERVER_VERSION

### How to enable proxy ###
#ENV HTTP_PROXY="http://proxy.example.no:80"
#ENV HTTPS_PROXY="https://proxy.example.no:80"
#ENV http_proxy="http://proxy.example.no:80"
#ENV https_proxy="https://proxy.example.no:80"
#RUN echo 'Acquire::http::Proxy "http://proxy.example.no:80";' >> /etc/apt/apt.conf
#RUN echo 'Acquire::https::Proxy "http://proxy.example.no:80";' >> /etc/apt/apt.conf
#RUN echo "http_proxy = http://proxy.example.no:80" >> /etc/wgetrc
#RUN echo "https_proxy = http://proxy.example.no:80" >> /etc/wgetrc
#RUN echo 'Acquire::http::Proxy "http://proxy.example.no:80";' >> /etc/apt/apt.conf
#RUN echo 'Acquire::https::Proxy "https://proxy.example.no:80";' >> /etc/apt/apt.conf
#RUN echo "http_proxy = http://proxy.example.no:80" >> /etc/wgetrc
#RUN echo "https_proxy = https://proxy.example.no:80" >> /etc/wgetrc

### How to install CA-certs ###
#COPY example-certs /usr/local/share/ca-certificates/example
#RUN update-ca-certificates
#ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

RUN apt-get update -y
RUN apt-get install git vim telnet hiera-eyaml openssh-client -y
