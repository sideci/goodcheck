FROM rubylang/ruby:2.6.3-bionic

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /goodcheck
WORKDIR /goodcheck
COPY . /goodcheck/
RUN gem build -o goodcheck.gem goodcheck.gemspec
RUN gem install goodcheck.gem

RUN mkdir /work
WORKDIR /work

ENTRYPOINT ["goodcheck"]
