FROM ruby:3.3-alpine

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local without 'development test' && \
    bundle install

COPY . .

EXPOSE 4567

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
