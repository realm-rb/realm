#!/usr/bin/env bash

cd realm-sns
bundle install
../.buildkite/wait-for-it.sh localstack:4566
bundle exec rspec \
  && bundle exec rubocop -c ../.rubocop.yml
