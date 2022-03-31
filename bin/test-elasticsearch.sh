#!/usr/bin/env bash

cd /app/realm-elasticsearch
bundle install
bundle exec rspec
bundle exec rubocop -c ../.rubocop.yml
