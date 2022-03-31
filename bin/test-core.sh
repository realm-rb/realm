#!/usr/bin/env bash

cd /app/realm-core
bundle install
bundle exec rspec
bundle exec rubocop -c ../.rubocop.yml
