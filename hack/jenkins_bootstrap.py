#!/usr/bin/env python
"""jenkins-trigger.py
Usage:
    jenkins-trigger.py --job <jobname> --jenkins-user <username> --jenkins-password <password> [--url <url>] [--sleep <sleep_time>] [--wait-timer <time>] [--encoding <type>] [--parameters <data>] [--debug]
    jenkins-trigger.py -h
Examples:
    jenkins-trigger.py  --job deploy_my_app -e text -u https://jenkins.example.com:8080 -p param1=1,param2=develop
Options:
  -j, --job <jobname>               Job Name.
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

from __future__ import print_function
from docopt import docopt
import requests
from time import sleep


class Trigger:
    def __init__(self, arguments):
        self.arguments = arguments
        self.debug = arguments['--debug']

        self.job = arguments['--job'][0]
        self.user = arguments['--jenkins-user']
        self.password = arguments['--jenkins-password']
        self.url = arguments['--url'][0]
        self.sleep = int(arguments['--sleep'][0])
        self.timer = int(arguments['--wait-timer'][0])
        self.encoding = arguments['--encoding'][0]
        if self.encoding.lower() in ["html", "text"]:
            self.encoding = self.encoding.title()
        else:
            print(" '%s' is not a valid encoding only support 'text', 'html'" % self.encoding)
            exit(1)
        if arguments['--parameters']:
            try:
                self.parameters = dict(u.split("=") for u in arguments['--parameters'][0].split(","))
            except ValueError:
                print("Your parameters should be in key=value format separated by ; for multi value i.e. x=1,b=2")
                exit(1)
        else:
            self.parameters = {}
        # print('URL: ' + self.url + ' job: ' + self.job + ' user: ' + self.user)

    def trigger_build(self):
        dns_fail_count = 0
        crumb = {}
        while dns_fail_count < 5 * 60 and crumb == "":
            try:
                url = self.url + '/crumbIssuer/api/json'
                print('Fetching: ', url)
                response = requests.get(url)
                print('Status to Crumb Fetch: ' + str(response.status_code))
                print('Response: ' + response.json())
            except Exception as err:
                print('Exception' + str(err))
                dns_fail_count += 1

        # Do a build request
        if self.parameters:
            build_url = self.url + "/job/" + self.job + "/buildWithParameters"
            print("Triggering a build via post @ ", build_url)
            build_request = requests.post(build_url, data=self.parameters,
                                          auth=(self.user, self.password),
                                          headers={"Jenkins-Crumb": crumb.get('crumb')})
        else:
            build_url = self.url + "/job/" + self.job + "/build"
            print("Triggering a build via get @ ", build_url)
            build_request = requests.post(build_url,
                                          auth=(self.user, self.password),
                                          headers={"Jenkins-Crumb": crumb.get('crumb')})

        if build_request.status_code == 201:
            queue_url = build_request.headers['location'] + "api/json"
            print("Build is queued @ ", queue_url)
        else:
            queue_url = None
            print("Your build somehow failed")
            print(build_request.status_code)
            print(build_request.text)
            exit(1)

        if queue_url.startswith('/'):
            queue_url = self.url + queue_url

        return queue_url

    def waiting_for_job_to_start(self, queue_url):
        # Poll till we get job number
        print("This is Stewart's script!")
        print("Starting polling for our job to start")
        timer = self.timer

        waiting_for_job = True
        job_url = ""
        while waiting_for_job:
            print('Checking Queue at: ' + queue_url)
            queue_request = requests.get(queue_url)
            if queue_request.json().get("why"):
                print(" . Waiting for job to start because :", queue_request.json().get("why").encode('utf-8').strip())
                timer -= 1
                sleep(self.sleep)
            else:
                sleep(self.sleep)
                # Refresh request to avoid synchronization issues
                attempts = 0
                queue_request = ""
                while attempts < 5 and queue_request == "":
                    try:
                        queue_request = requests.get(queue_url)
                    except Exception:
                        attempts += 1
                        sleep(self.sleep)
                waiting_for_job = False
                job_url = ""
                attempts = 0
                while attempts < 5 * 60 and job_url == "":
                    try:
                        job_url = queue_request.json().get("executable").get("url")
                    except Exception:
                        attempts += 1
                        sleep(self.sleep)
                job_url = queue_request.json().get("executable").get("url")
                print(" Job is being build number: ", job_url)

            if timer == 0:
                print(" time out waiting for job to start")
                exit(1)
        # Return URL of job (enforcing it ends with / to deal with different jenkins versions)
        if not job_url.endswith('/'):
            job_url += '/'

        print('Job URL: ' + job_url)
        return job_url

    def console_output(self, job_url):
        # Get job console till job stops
        start_at = 0
        stream_open = True
        check_job_status = 0
        dns_fail_count = 0

        console_requests = requests.session()

        response = console_requests.get(self.url + '/crumbIssuer/api/json', auth=(self.user, self.password))
        # print('Received HTTP ' + str(response.status_code) + ' with ' + response.text)
        # print('Received Cookies ' + str(response.cookies.get_dict()))
        crumb = response.json().get('crumb')
        # print('crumb: ' + str(crumb))

        # Build the URLs necessary
        console_url = job_url + 'logText/progressive' + self.encoding
        job_status_url = job_url + "api/json"

        print('Getting Console output: ' + console_url)
        while stream_open:
            console_response = console_requests.post(console_url, data={'start': start_at},
                                                     auth=(self.user, self.password),
                                                     )
            # print('Headers: ' + str(console_response.headers))
            content_length = int(console_response.headers.get("Content-Length", -1))
            # print('Received HTTP ' + str(console_response.status_code) + ' Content of ' + str(content_length)
            #       + ' bytes\n')

            while console_response.status_code != 200 and dns_fail_count <= 5 * 60 / self.sleep:

                dns_fail_count += 1
                if dns_fail_count >= 5 * 60 / self.sleep:
                    print("Uh oh we have an issue ...")
                    print(console_response.content)
                    print(console_response.headers)
                    exit(1)
                sleep(self.sleep)
                console_response = console_requests.post(console_url, data={'start': start_at},
                                                         auth=(self.user, self.password))

            if content_length == 0:
                sleep(self.sleep)
                check_job_status += 1
            else:
                check_job_status = 0
                # Print to screen console
                print(console_response.text)
                sleep(self.sleep)
                start_at = int(console_response.headers.get("X-Text-Size", 0))
                # Check to see if all data is included and no continuation and go into look at status
                if start_at == 0:
                    check_job_status = 2

            # No content for a while lets check if job is still running
            if check_job_status > 1:
                # print('Getting Status: ' + job_status_url)
                job_requests = console_requests.get(job_status_url)
                # print('Received HTTP ' + str(console_response.status_code))
                job_building = job_requests.json().get("building")
                if not job_building:
                    # We are done
                    print("stream ended")
                    stream_open = False

                    # Handle output
                    job_result = job_requests.json().get("result")
                    if job_result == "FAILURE":
                        raise Exception(
                            "This python exception is raised to trigger the GitHub status as a failure. It is not "
                            "related to the build failures in any way, it is simply a build check and wrapper "
                            "function. Please see actual build errors above.")
                else:
                    # Job is still running
                    check_job_status = 0

    def main(self):
        queue_url = self.trigger_build()
        job_url = self.waiting_for_job_to_start(queue_url)
        self.console_output(job_url)


if __name__ == '__main__':
    ARGUMENTS = docopt(__doc__)
    MY_TRIGGER = Trigger(ARGUMENTS)
    MY_TRIGGER.main()
