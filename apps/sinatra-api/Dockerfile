FROM ruby:3.3-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential libpq-dev git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development' \
 && bundle install --jobs 4 --retry 2

COPY . .

EXPOSE 8080

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]
