#!/bin/bash

./vasm/vasm6502_oldstyle \
    -Fbin \ # Use binary output module
    -dotdir \ # Use .directives
    -wdc02 \  # Use WDC65c02 instruction set
    src/robo-runner.s && \
minipro -p 'AT28C256' -w a.out