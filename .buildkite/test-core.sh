#!/usr/bin/env bash

.buildkite/wait-for-it.sh localstack:4566
cd realm-core
bundle install
bundle exec rspec
bundle exec rubocop -c ../.rubocop.yml
