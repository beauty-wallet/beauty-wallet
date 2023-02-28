#!/bin/bash

./build_iconv.sh || exit 1
./build_boost.sh || exit 1
./build_openssl.sh || exit 1
./build_sodium.sh || exit 1
./build_unbound.sh || exit 1
./build_zmq.sh || exit 1
./build_monero.sh || exit 1
