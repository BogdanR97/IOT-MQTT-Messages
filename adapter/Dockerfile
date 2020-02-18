FROM ruby:2.5
RUN mkdir /adapter-utils
WORKDIR /adapter-utils
COPY Gemfile /adapter-utils/Gemfile
COPY Gemfile.lock /adapter-utils/Gemfile.lock
RUN bundle install
COPY . /adapter-utils
