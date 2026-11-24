#!/bin/sh
# Chromium launcher for small Railway plans. Makes Chromium the kernel's first
# choice when the service runs out of memory, so a heavy page crashes only its
# render (the server then indexes the page as fetched) instead of the server.
echo 1000 > /proc/self/oom_score_adj 2>/dev/null || true
if [ "${CHROMIUM_LOW_MEMORY:-0}" = 1 ]; then
  exec /usr/bin/chromium --renderer-process-limit=1 --disable-gpu \
    --disable-site-isolation-trials --disable-features=site-per-process \
    --js-flags=--max-old-space-size=128 "$@"
fi
exec /usr/bin/chromium "$@"
