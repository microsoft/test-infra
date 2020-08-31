#!/usr/bin/env python

"""Bootstraps starting a test job.

The following should already be done:
  git checkout http://k8s.io/test-infra
  cd $WORKSPACE
  test-infra/jenkins/bootstrap.py <--repo=R || --bare> <--job=J> <--pull=P || --branch=B>

The bootstrapper now does the following:
  # Note start time
  # check out repoes defined in --repo
  # note job started
  # call runner defined in $JOB.json
  # upload artifacts (this will change later)
  # upload build-log.txt
  # note job ended

The contract with the runner is as follows:
  * Runner must exit non-zero if job fails for any reason.
"""


import argparse
import contextlib
import json
import logging
import os
import pipes
import random
import re
import select
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib2
import requests


def build_start(args):
    logging.warning(
        '**************************************************************************\n'
        'Jenkins job starting!\n'
        '**************************************************************************'
    )

    jenkins_job = args.job
    jenkins_url=args.jenkins_url

    jenkins_user=args.jenkins_user
    jenkins_password=args.jenkins_password
    jenkins_token=args.jenkins_token

    logging.warning(
        '**************************************************************************\n'
        'Getting Crumb for Jenkins job!\n'
        '**************************************************************************'
    )

    crumb = requests.get('https://' + jenkins_user + ':' + jenkins_password + '@' + jenkins_url + '/crumbIssuer/api/json').json()

    print crumb
    
    resp = requests.post('https://' + jenkins_user + ':' + jenkins_password + '@' + jenkins_url + '/job/' + jenkins_job + '/buildWithParameters?token=' + jenkins_token, 
                   auth=(jenkins_user,jenkins_password), 
                   headers={"Jenkins-Crumb":'ed0a56919acd170eff92a28fa7306f1331b8f3ddea30fd95515e3f04c7ae9a74'})
    print(jenkins_job)
    print(jenkins_url)
    print(jenkins_user)
    print(jenkins_password)
    print(jenkins_token)



def bootstrap(args):

    """Clone repo at pull/branch into root and run job script."""
    logging.warning(
        '**************************************************************************\n'
        'bootstrap.py is WIP, please contact the repo admins if you see anything that does not compute!\n'
        '**************************************************************************'
    )

    jenkins_job = args.job
    jenkins_url=args.jenkins_url

    jenkins_user=args.jenkins_user
    jenkins_password=args.jenkins_password
    jenkins_token=args.jenkins_token

    print(jenkins_job)
    print(jenkins_url)
    print(jenkins_user)
    print(jenkins_password)
    print(jenkins_token)

    started = time.time()
    print(started)

    build = build_start(ARGS)

def parse_args(arguments=None):
    """Parse arguments or sys.argv[1:]."""
    if arguments is None:
        arguments = sys.argv[1:]
    parser = argparse.ArgumentParser()

    parser.add_argument('--job', required=True, help='Name of the job to run')
    parser.add_argument('--jenkins-url', required=True, help='jenkins master url')
    parser.add_argument('--jenkins-user', required=True, help='jenkins username')
    parser.add_argument('--jenkins-password', required=True, help='jenkins password')
    parser.add_argument('--jenkins-token', required=True, help='jenkins build token')

    extra_job_args = []
    if '--' in arguments:
        index = arguments.index('--')
        arguments, extra_job_args = arguments[:index], arguments[index+1:]
    args = parser.parse_args(arguments)
    setattr(args, 'extra_job_args', extra_job_args)
    return args


if __name__ == '__main__':
    ARGS = parse_args()
    bootstrap(ARGS)

