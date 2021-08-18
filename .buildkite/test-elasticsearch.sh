#!/usr/bin/env bash

cd realm-elasticsearch
bundle install
bundle exec rspec \
  && bundle exec rubocop -c ../.rubocop.yml
