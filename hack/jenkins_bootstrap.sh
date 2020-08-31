
export JENKINS_USER="jenkins-trigger"
export JENKINS_PASSWORD="1194d4e8e412ea2d953da2655673c2ab23"
export JENKINS_TOKEN="Openenclave1!"
export JENKINS_JOB="jenkins-trigger"
export JENKINS_JOB_PATH="job"

DEBUG=0

# Begin Build
curl --user ${JENKINS_USER}:${JENKINS_PASSWORD} https://oe-prow-testing.uksouth.cloudapp.azure.com/${JENKINS_JOB_PATH}/${JENKINS_JOB}/buildWithParameters?token=${JENKINS_TOKEN}

# Job Status Info
get_last_job_status="curl --user ${JENKINS_USER}:${JENKINS_PASSWORD} https://oe-prow-testing.uksouth.cloudapp.azure.com/${JENKINS_JOB_PATH}/${JENKINS_JOB}/lastBuild/api/json?token=${JENKINS_TOKEN}"

# Get Job ID
## TODO Modify to use the headers from the returned Location header, current bug where if a job hasn't started yet it will point to the wrong job

job_id=$(${get_last_job_status} | jq '.number')

# Sleep through quiet period
echo "Sleep through quiet period"
sleep 15s

get_current_job_status="curl --user ${JENKINS_USER}:${JENKINS_PASSWORD} https://oe-prow-testing.uksouth.cloudapp.azure.com/${JENKINS_JOB_PATH}/${JENKINS_JOB}/${job_id}/api/json?token=${JENKINS_TOKEN}"

# Set default 
building=true

# Wait for Jenkins to finish job
while [ $building = "true" ]; do
    # Get Build status
    current_build_status=$(${get_current_job_status} | jq '.building')
    
    if [ $current_build_status == "false" ]; then
        echo "Build is complete!"
        building=false
        break
    else
        echo "Job is still running at: https://oe-prow-testing.uksouth.cloudapp.azure.com/${JENKINS_JOB_PATH}/${JENKINS_JOB}/${job_id}/console"
    fi

    sleep 30s
done