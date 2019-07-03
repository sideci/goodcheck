FROM ruby:2.6.3

RUN apt-get update -y && \
     apt-get install -y locales task-english && \
     rm -rf /var/lib/apt/lists/*
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale en_US.UTF-8
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN mkdir /goodcheck
WORKDIR /goodcheck
COPY . /goodcheck/
RUN rake install

RUN mkdir /work
WORKDIR /work

ENTRYPOINT ["goodcheck"]
