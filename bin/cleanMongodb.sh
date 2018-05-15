#!/bin/bash

cd "$1"
find . | grep test | rm -rf
