#!/bin/bash

exec taplo format --config ~/.config/taplo/taplo.toml - < "$1"
