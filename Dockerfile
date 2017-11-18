FROM ruby:2.3
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgmp3-dev libgmp-dev bundler\
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./
RUN bundle install
COPY . .
CMD ["bundle", "exec", "puma", "-p", "4000"]
EXPOSE 4000
