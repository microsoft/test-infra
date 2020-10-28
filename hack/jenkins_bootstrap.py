#!/usr/bin/env python
"""jenkins-trigger.py

Usage:
    jenkins-trigger.py --job <jobname> --jenkins-user <username> --jenkins-password <password> [--url <url>] [--sleep <sleep_time>] [--encoding <type>] [--parameters <data>] [--wait-timer <time>] [--debug]
    jenkins-trigger.py -h

Examples:
    jenkins-trigger.py  --job deploy_my_app -e text -u https://jenkins.example.com:8080 -p param1=1,param2=develop

Options:
  -j, --job <jobname>               Job name.
  --jenkins-user <username>         Jenkins username.
  --jenkins-password <password>     Jenkins Password.
  -u, --url <url>                   Jenkins URL [default: http://localhost:8080]
  -s, --sleep <sleep_time>          Sleep time between polling requests [default: 2]
  -w, --wait-timer <time>           Wait time in queue [default: 100]
  -e, --encoding <type>             Encoding type supports text or html [default: html]
  -p, --parameters <data>           Comma separated job parameters i.e. a=1,b=2
  -d, --debug                       Print debug info
  -h, --help                        Show this screen and exit.
"""

import requests
import json
from docopt import docopt
from time import sleep
from datetime import datetime


class Trigger():
    def __init__(self, arguments):
        self.arguments = arguments
        self.debug = arguments['--debug'] 
        if self.debug:
            print "argument = ", arguments
        self.url = arguments['--url']
        self.job = arguments['--job']
        self.user = arguments['--jenkins-user']
        self.password = arguments['--jenkins-password']
        self.timer = int(arguments['--wait-timer'])
        self.sleep = int(arguments['--sleep'])
        self.encoding = arguments['--encoding']
        self.debug = arguments['--debug']
        if self.encoding.lower() in ["html", "text"]:
            self.encoding = self.encoding.title()
        else:
            print " '%s' is not a valid encoding only support 'text', 'html'" % self.encoding 
            exit(1)
        if arguments['--parameters']:
            try:
                self.parameters = dict(u.split("=") for u in arguments['--parameters'].split(","))
            except ValueError:
                print "Your parameters should be in key=value format separated by ; for multi value i.e. x=1,b=2"
                exit(1)
        else:
            self.parameters = False

    def trigger_build(self):
        crumb = ""
        dns_fail_count = 0
        while dns_fail_count < 5*60 and crumb == "":
            try:
                crumb = requests.get(self.url + '/crumbIssuer/api/json',
                                auth=(self.user, self.password)).json()
            except Exception:
                dns_fail_count += 1

        # Do a build request
        if self.parameters:
            build_url = self.url + "/job/" + self.job + "/buildWithParameters"
            print "Triggering a build via post @ ", build_url
            build_request = ""
            while build_request == "":
                build_request = requests.post(build_url, data=self.parameters,
                                          auth=(self.user, self.password),
                                          headers={"Jenkins-Crumb": crumb.get('crumb')})
        else:
            build_url = self.url + "/job/" + self.job + "/build"
            print "Triggering a build via get @ ", build_url
            build_request = ""
            while build_request == "":
                build_request = requests.post(build_url,
                                         auth=(self.user, self.password),
                                         headers={"Jenkins-Crumb": crumb.get('crumb')})

        if build_request.status_code == 201:
            queue_url = build_request.headers['location'] + "api/json"
            print "Build is queued @ ", queue_url
        else:
            print "Your build somehow failed"
            print build_request.status_code
            print build_request.text
            return ""
        return queue_url

    def waiting_for_job_to_start(self, queue_url):
        # Poll till we get job number
        print ""
        print "Starting polling for our job to start"
        timer = self.timer

        waiting_for_job = True
        while waiting_for_job:
            queue_request = requests.get(queue_url)
            if queue_request.ok and queue_request.json().get("why") != None:
                print " . Waiting for job to start because :", queue_request.json().get("why").encode('utf-8').strip()
                timer -= 1
                sleep(self.sleep)
            else:
                sleep(self.sleep)
                # Refresh request to avoid synchronization issues
                attempts = 0
                queue_request = "" 
                while attempts < 10 * 60 and queue_request == "":
                    try:
                        queue_request = requests.get(queue_url)
                    except Exception:
                        attempts += 1
                        sleep(self.sleep)
                waiting_for_job = False
                job_number = ""
                attempts = 0
                while attempts < 5*60 and job_number == "":
                    try:
                        job_number = queue_request.json().get("executable").get("number")
                    except Exception:
                        attempts += 1
                        sleep(self.sleep)
                print " Job is being build number: ", job_number

            if timer == 0:
                print " time out waiting for job to start"
                exit(1)
        # Return the job numner of the working
        return job_number

    def console_output(self, job_number):
        # Get job console till job stops
        job_url = self.url + "/job/" + self.job + "/" + str(job_number).encode('utf-8').strip() + "/logText/progressive" + self.encoding
        blue_ocean_url = self.url + "/blue/organizations/jenkins/" + self.job + "/detail/" + self.job + "/" + str(job_number).encode('utf-8').strip() + '/pipeline'
        print " View blue ocean @ ", blue_ocean_url
        print " Getting Console output @ ", job_url
        start_at = 0
        stream_open = True
        check_job_status = 0
        dns_fail_count = 0

        crumb = requests.get(self.url + '/crumbIssuer/api/json',
                             auth=(self.user, self.password)).json()

        console_requests = requests.session()
        while stream_open:
            console_response = console_requests.post(job_url, data={'start': start_at },
                                                     auth=(self.user, self.password),
                                                     headers={"Jenkins-Crumb": crumb.get('crumb')})
            content_length = int(console_response.headers.get("Content-Length", -1))
            
            while console_response.status_code != 200 and dns_fail_count <= 10 * 60 /self.sleep:
                
                dns_fail_count += 1
                if dns_fail_count >= 10 * 60 /self.sleep:
                    print "Uh oh we have an issue ..."
                    print console_response.content
                    print console_response.headers
                    exit(1)
                sleep(self.sleep)
                console_response = console_requests.post(job_url, data={'start': start_at },
                                                        auth=(self.user, self.password),
                                                        headers={"Jenkins-Crumb": crumb.get('crumb')})

            if content_length == 0:
                sleep(self.sleep)
                check_job_status += 1
            else:
                check_job_status = 0
                # Print to screen console
                print console_response.content
                sleep(self.sleep)
                start_at = int(console_response.headers.get("X-Text-Size"))

            # No content for a while lets check if job is still running
            if check_job_status > 1:
                job_status_url = self.url + "/job/" + self.job + "/" + str(job_number).encode('utf-8').strip() + "/api/json"
                job_requests = requests.get(job_status_url)
                job_bulding = job_requests.json().get("building")
                if not job_bulding:
                    # We are done
                    print "stream ended"
                    stream_open = False

                    # Handle output
                    job_result = job_requests.json().get("result")
                    if job_result == "FAILURE":
                        raise Exception("This python exception is raised to trigger the GitHub status as a failure. It is not related to the build failures in any way, it is simply a build check and wrapper function. Please see actual build errors above.")
                else:
                    # Job is still running
                    check_job_status = 0

    def main(self):
        try:
            dateTimeObj = datetime.now()
            print(dateTimeObj)
            queue_url = ""
            while queue_url == "":
                queue_url = self.trigger_build()

            job_number = ""
            while job_number == "":
                job_number = self.waiting_for_job_to_start(queue_url)

            self.console_output(job_number)
            dateTimeObj = datetime.now()
            print(dateTimeObj)
        except Exception:
            print("Exception!")
            dateTimeObj = datetime.now()
            print(dateTimeObj)
        finally:
            print("Finally!")
            dateTimeObj = datetime.now()
            print(dateTimeObj)
            

if __name__ == '__main__':
    arguments = docopt(__doc__)
    myrigger = Trigger(arguments)
    myrigger.main()
