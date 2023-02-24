#!/bin/sh

## /images/ --> ../../static/images/
sed -i "" 's/\/images\//\.\.\/\.\.\/static\/images\//' content/posts/*.md