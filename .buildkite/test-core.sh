#!/usr/bin/env bash

cd realm-core
bundle install
bundle exec rspec \
  && bundle exec rubocop -c ../.rubocop.yml
