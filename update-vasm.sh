#!/bin/bash

curl http://sun.hasenbraten.de/vasm/release/vasm.tar.gz -o vasm.tar.gz && \
tar -xf vasm.tar.gz && \
cd vasm && make CPU=6502 SYNTAX=oldstyle && \
rm ../vasm.tar.gz
cd -