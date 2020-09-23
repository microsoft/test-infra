# Open Enclave Test Infrastructure


[![Build status](http://oe-prow-status.uksouth.cloudapp.azure.com/badge.svg?jobs=ci-openenclave-test-infra-*)](http://oe-prow-status.uksouth.cloudapp.azure.com/badge.svg?jobs=ci-openenclave-test-infra-*)
[![Post Build status](http://oe-prow-status.uksouth.cloudapp.azure.com/badge.svg?jobs=post-openenclave-test-infra-*)](https://oe-prow-status.uksouth.cloudapp.azure.com/badge.svg?jobs=post-openenclave-test-infra-*)
![GitGuardian scan](https://github.com/openenclave-ci/test-infra/workflows/GitGuardian%20scan/badge.svg)

[![Slack Channel](https://img.shields.io/badge/Slack-Join-purple)](https://openenclaveciteam.slack.com/)
[![Element Channel](https://img.shields.io/badge/Slack-Join-green)](https://matrix.to/#/!iUVElxxPQQMxGLHAJH:openenclave.io?via=openenclave.io)

This repository contains tools and configuration files for the testing and automation needs of the OpenEnclave project.

CI Job Management
------------------------------

Open Enclave uses a [prow](https://github.com/kubernetes/test-infra/blob/master/prow) instance at [oe-prow](http://oe-prow-status.uksouth.cloudapp.azure.com/) to handle CI and automation for the entire organization. Everyone can participate in a self-service PR-based workflow, where changes are automatically deployed after they have been reviewed. All job configs are located in [config/jobs](config/jobs). For more about how to build with prow, please see the [kubernetes/test-infra](https://github.com/kubernetes/test-infra#ci-job-management) project.

- [Add or update job configs](https://github.com/kubernetes/test-infra/blob/master/config/jobs/README.md#adding-or-updating-jobs)
- [Delete job configs](https://github.com/kubernetes/test-infra/blob/master/config/jobs/README.md#deleting-jobs)
- [Test job configs locally](https://github.com/kubernetes/test-infra/blob/master/config/jobs/README.md#testing-jobs-locally)
- [Trigger jobs on PRs using bot commmands](https://go.k8s.io/bot-commands)

