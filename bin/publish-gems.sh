#!/usr/bin/env bash

all_gems=(realm-core realm-elasticsearch realm-rom realm-sns)
gems_to_publish=${1:-${all_gems[@]}}
version=$(<VERSION)
root=$(pwd)

for name in $gems_to_publish; do
  cd "${root}/${name}"
  gem build "${name}.gemspec"
  gem push "${name}-${version}.gem"
  rm "${name}-${version}.gem"
done
