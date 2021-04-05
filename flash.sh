#!/bin/bash

./vasm/vasm6502_oldstyle -Fbin -dotdir -wdc02 src/robo-runner.s && \
minipro -p 'AT28C256' -w a.out