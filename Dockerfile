FROM ruby:2.7-alpine3.12 AS base

ENV BUNDLE_SILENCE_ROOT_WARNING=1

RUN apk add --no-cache build-base bash curl postgresql-dev sqlite-dev libffi-dev less

WORKDIR /app
