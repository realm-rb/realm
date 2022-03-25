#!/usr/bin/env bash

cd realm-elasticsearch
bundle install
../.buildkite/wait-for-it.sh elasticsearch:9200
bundle exec rspec \
  && bundle exec rubocop -c ../.rubocop.yml
