FROM ruby:2.7-alpine3.12 AS base

ENV BUNDLE_SILENCE_ROOT_WARNING=1

RUN apk add --no-cache build-base bash curl sqlite-dev libffi-dev

WORKDIR /app

COPY Gemfile realm.gemspec VERSION ./
RUN bundle install -j4 -r3
