#!/bin/bash
set -e
git tag -d v1.0.0
git tag v1.0.0
git push origin --tags --force