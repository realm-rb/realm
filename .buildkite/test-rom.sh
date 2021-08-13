#!/usr/bin/env bash

cd realm-rom
bundle install
bundle exec rspec \
  && bundle exec rubocop -c ../.rubocop.yml
