######
This document is to highlight some possible scenarios that you can run into whole using prow. 

Please read this document in this way.

Error description
```
Error example output.
```
Explaination: Why this happens, if it is a bug, expected and what can be done in the future.

Resolution: Do this to unblock yourself.


###
Could not resolve host: github

```
# FAILED!
# Cloning openenclave/openenclave at master
$ mkdir -p /home/prow/go/src/github.com/openenclave/openenclave
$ git init
Initialized empty Git repository in /home/prow/go/src/github.com/openenclave/openenclave/.git/
$ git config user.name ci-robot
$ git config user.email ci-robot@k8s.io
$ git fetch https://github.com/openenclave/openenclave.git --tags --prune
fatal: unable to access 'https://github.com/openenclave/openenclave.git/': Could not resolve host: github.com
# Error: exit status 128
```
Explaination: What we have witnessed is this happens when a great many 30+ tests are triggered at the same time. This is likely due to the underlying github api, causing some to pass and some to not be able to resolve the DNS. The long term solution is to allow multiple clusters to build jobs and distribute the workload.

Resolution: comment /retest on your PR, it's considered a flake at this time.