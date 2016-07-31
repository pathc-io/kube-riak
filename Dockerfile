FROM debian:jessie

ENV RIAK_VERSION 2.0.2-1

ENV ERLANG_VERSION 17.5


# Install the build tools (dpkg-dev g++ gcc libc6-dev make)
RUN apt-get update && apt-get -y install \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng3 \
    libssh-dev \
    libwxgtk3.0-dev \
    unixodbc-dev \
    wget \
    git \
    libpam0g-dev

RUN mkdir -p ~/code/erlang && cd ~/code/erlang && \
    wget http://www.erlang.org/download/otp_src_17.5.tar.gz && \
    tar -xvzf otp_src_17.5.tar.gz && chmod -R 777 otp_src_17.5 && \
    cd otp_src_17.5 && ./configure && make && make install


RUN git clone git://github.com/basho/riak.git
RUN cd riak && make locked-deps
RUN cd riak && make rel


# Tune Riak configuration settings for the container
RUN sed -i.bak 's/listener.http.internal = 127.0.0.1/listener.http.internal = 0.0.0.0/' /riak/rel/riak/etc/riak.conf && \
    sed -i.bak 's/listener.protobuf.internal = 127.0.0.1/listener.protobuf.internal = 0.0.0.0/' /riak/rel/riak/etc/riak.conf && \
    echo "anti_entropy.concurrency_limit = 1" >> /riak/rel/riak/etc/riak.conf && \
    echo "javascript.map_pool_size = 0" >> /riak/rel/riak/etc/riak.conf && \
    echo "javascript.reduce_pool_size = 0" >> /riak/rel/riak/etc/riak.conf && \
    echo "javascript.hook_pool_size = 0" >> /riak/rel/riak/etc/riak.conf

# Open ports for HTTP and Protocol Buffers
EXPOSE 8087 8098

CMD ["/riak/rel/riak/bin/riak start"]