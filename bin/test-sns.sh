#!/usr/bin/env bash

.buildkite/wait-for-it.sh localstack:4566
cd /app/realm-sns
bundle install
bundle exec rspec
bundle exec rubocop -c ../.rubocop.yml
