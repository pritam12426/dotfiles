#!/bin/bash

cat "$1" | taplo format --config "$HOME/.config/taplo/taplo.toml" -
