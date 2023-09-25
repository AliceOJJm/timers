FROM ruby:3.2.2

ADD . /lemonade-timers
WORKDIR /lemonade-timers
RUN bundle install

EXPOSE 3000

CMD ["bash"]
