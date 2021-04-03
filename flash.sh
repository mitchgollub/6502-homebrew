#!/bin/bash

./vasm/vasm6502_oldstyle -Fbin -dotdir src/marquee.s && \
minipro -p 'AT28C256' -w a.out