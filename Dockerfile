FROM rubylang/ruby:2.6.2-bionic

RUN mkdir /goodcheck
WORKDIR /goodcheck
COPY . /goodcheck/
RUN rake install

RUN mkdir /work
WORKDIR /work

ENTRYPOINT ["goodcheck"]
