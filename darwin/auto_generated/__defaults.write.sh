#!/bin/sh
defaults write com.apple.dock autohide-time-modifier -float 0.5;
defaults write com.apple.dock autohide-delay -float 0;
defaults write com.apple.dock showhidden -bool YES
defaults write com.apple.dock mouse-over-hilite-stack -bool true

defaults write -g ApplePressAndHoldEnabled -bool false

killall Dock
