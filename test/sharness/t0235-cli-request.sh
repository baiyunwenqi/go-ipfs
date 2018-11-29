#!/usr/bin/env bash
#
# Copyright (c) 2015 Jeromy Johnson
# MIT Licensed; see the LICENSE file in this repository.
#

test_description="test http requests made by cli"

. lib/test-lib.sh

test_init_ipfs

test_expect_success "start nc" '
  rm -f nc_out nc_in && mkfifo nc_in nc_out
  # 1. Abuse cat to buffer output.
  # 2. Put cat in a subshell so we capture the PID of nc.
  nc -k -l 5005 < nc_in > >(cat > nc_out) &
  NCPID=$!
  echo "" > nc_in
  while ! nc -z 127.0.0.1 5005; do
      go-sleep 100ms
  done
'

test_expect_success "can make http request against nc server" '
  cat >nc_in <<EOF
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 1

.
EOF
ipfs cat /ipfs/Qmabcdef --api /ip4/127.0.0.1/tcp/5005
'

test_expect_success "request looks good and doesn't contain api flag" '
  grep -v "api=" | grep -q "POST /api/v0/cat" nc_out
'

test_expect_success "output does not contain multipart info" '
  ! sed -n -e "0,/^$/p" | grep multipart
'

test_expect_success "stop nc" '
  kill "$NCPID"
'

test_done
