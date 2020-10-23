#!/usr/bin/env bash
#
# This is used to install plugins to the Jenkins master
# Should be ran after Jenkins master is deployed OR if there are plugin updates you want to force install
#
# Instructions:
#   1. Update the configuration variables in the section below.
#   2. chmod +x ./jenkins-install-plugins.sh
#   3. ./jenkins-install-plugins.sh
#
# -----------BEGIN-CONFIGURATION-----------
set -e

# List of Jenkins Plugins to install.
# You can browse existing plugins here: https://updates.jenkins.io/download/plugins/
#
# Note: This does not manage dependencies.
# i.e. you will need to also add dependencies of the package you are adding, if it does not already exist in this list

readonly PLUGIN_URLS=(
    https://updates.jenkins-ci.org/latest/ace-editor.hpi
    https://updates.jenkins-ci.org/latest/apache-httpcomponents-client-4-api.hpi
    https://updates.jenkins-ci.org/latest/authentication-tokens.hpi
    https://updates.jenkins-ci.org/latest/azure-commons.hpi
    https://updates.jenkins-ci.org/latest/azure-credentials.hpi
    https://updates.jenkins-ci.org/latest/azure-keyvault.hpi
    https://updates.jenkins-ci.org/latest/azure-vm-agents.hpi
    https://updates.jenkins-ci.org/latest/bootstrap4-api.hpi
    https://updates.jenkins-ci.org/latest/bouncycastle-api.hpi
    https://updates.jenkins-ci.org/latest/branch-api.hpi
    https://updates.jenkins-ci.org/latest/checks-api.hpi
    https://updates.jenkins-ci.org/latest/cloudbees-folder.hpi
    https://updates.jenkins-ci.org/latest/cloud-stats.hpi
    https://updates.jenkins-ci.org/latest/command-launcher.hpi
    https://updates.jenkins-ci.org/latest/configuration-as-code.hpi
    https://updates.jenkins-ci.org/latest/config-file-provider.hpi
    https://updates.jenkins-ci.org/latest/credentials-binding.hpi
    https://updates.jenkins-ci.org/latest/credentials.hpi
    https://updates.jenkins-ci.org/latest/display-url-api.hpi
    https://updates.jenkins-ci.org/latest/docker-commons.hpi
    https://updates.jenkins-ci.org/latest/docker-plugin.hpi
    https://updates.jenkins-ci.org/latest/durable-task.hpi
    https://updates.jenkins-ci.org/latest/echarts-api.hpi
    https://updates.jenkins-ci.org/latest/font-awesome-api.hpi
    https://updates.jenkins-ci.org/latest/git-client.hpi
    https://updates.jenkins-ci.org/latest/git-server.hpi
    https://updates.jenkins-ci.org/latest/git.hpi
    https://updates.jenkins-ci.org/latest/github-api.hpi
    https://updates.jenkins-ci.org/latest/github-branch-source.hpi
    https://updates.jenkins-ci.org/latest/github.hpi
    https://updates.jenkins-ci.org/latest/github-oauth.hpi
    https://updates.jenkins-ci.org/latest/groovy.hpi
    https://updates.jenkins-ci.org/latest/handlebars.hpi
    https://updates.jenkins-ci.org/latest/jackson2-api.hpi
    https://updates.jenkins-ci.org/latest/jaxb.hpi
    https://updates.jenkins-ci.org/latest/jdk-tool.hpi
    https://updates.jenkins-ci.org/latest/job-dsl.hpi
    https://updates.jenkins-ci.org/latest/jquery3-api.hpi
    https://updates.jenkins-ci.org/latest/jquery-detached.hpi
    https://updates.jenkins-ci.org/latest/jsch.hpi
    https://updates.jenkins-ci.org/latest/junit.hpi
    https://updates.jenkins-ci.org/latest/lockable-resources.hpi
    https://updates.jenkins-ci.org/latest/mailer.hpi
    https://updates.jenkins-ci.org/latest/matrix-project.hpi
    https://updates.jenkins-ci.org/latest/momentjs.hpi
    https://updates.jenkins-ci.org/latest/okhttp-api.hpi
    https://updates.jenkins-ci.org/latest/pipeline-build-step.hpi
    https://updates.jenkins-ci.org/latest/pipeline-graph-analysis.hpi
    https://updates.jenkins-ci.org/latest/pipeline-input-step.hpi
    https://updates.jenkins-ci.org/latest/pipeline-milestone-step.hpi
    https://updates.jenkins-ci.org/latest/pipeline-model-api.hpi
    https://updates.jenkins-ci.org/latest/pipeline-model-definition.hpi
    https://updates.jenkins-ci.org/latest/pipeline-model-extensions.hpi
    https://updates.jenkins-ci.org/latest/pipeline-multibranch-defaults.hpi
    https://updates.jenkins-ci.org/latest/pipeline-rest-api.hpi
    https://updates.jenkins-ci.org/latest/pipeline-stage-step.hpi
    https://updates.jenkins-ci.org/latest/pipeline-stage-tags-metadata.hpi
    https://updates.jenkins-ci.org/latest/pipeline-stage-view.hpi
    https://updates.jenkins-ci.org/latest/plain-credentials.hpi
    https://updates.jenkins-ci.org/latest/plugin-util-api.hpi
    https://updates.jenkins-ci.org/latest/popper-api.hpi
    https://updates.jenkins-ci.org/latest/scm-api.hpi
    https://updates.jenkins-ci.org/latest/script-security.hpi
    https://updates.jenkins-ci.org/latest/snakeyaml-api.hpi
    https://updates.jenkins-ci.org/latest/ssh-credentials.hpi
    https://updates.jenkins-ci.org/latest/structs.hpi
    https://updates.jenkins-ci.org/latest/token-macro.hpi
    https://updates.jenkins-ci.org/latest/trilead-api.hpi
    https://updates.jenkins-ci.org/latest/workflow-aggregator.hpi
    https://updates.jenkins-ci.org/latest/workflow-api.hpi
    https://updates.jenkins-ci.org/latest/workflow-basic-steps.hpi
    https://updates.jenkins-ci.org/latest/workflow-cps.hpi
    https://updates.jenkins-ci.org/latest/workflow-cps-global-lib.hpi
    https://updates.jenkins-ci.org/latest/workflow-durable-task-step.hpi
    https://updates.jenkins-ci.org/latest/workflow-job.hpi
    https://updates.jenkins-ci.org/latest/workflow-multibranch.hpi
    https://updates.jenkins-ci.org/latest/workflow-scm-step.hpi
    https://updates.jenkins-ci.org/latest/workflow-step-api.hpi
    https://updates.jenkins-ci.org/latest/workflow-support.hpi
    https://updates.jenkins-ci.org/latest/ws-cleanup.hpi
)
# Home directory for the Jenkins master.
# This should not need to change unless you willfully changed the Jenkins home directly elsewhere
readonly JENKINS_HOME=/var/jenkins_home

# ------------END-CONFIGURATION------------

# Get Jenkins Master Pod ID
readonly JENKINS_MASTER_POD=$(kubectl get pods --field-selector=status.phase=Running -o 'jsonpath={.items[0].metadata.name}' -l app=jenkins-master)

for PLUGIN_URL in ${PLUGIN_URLS[@]}; do
    HPI_FILE=$(basename ${PLUGIN_URL})
    JPI_FILE=$(echo ${HPI_FILE} | sed 's/hpi/jpi/')
    curl --location --fail --silent --show-error ${PLUGIN_URL} --output ${HPI_FILE}
    if [[ -f ${HPI_FILE} ]]; then
        # Check for existing JPI plugins
        kubectl exec ${JENKINS_MASTER_POD} -- bash -c " \
            if [[ -f ${JENKINS_HOME}/plugins/${JPI_FILE} ]]; then \
                rm ${JENKINS_HOME}/plugins/${JPI_FILE}; \
                echo 'Removed existing ${JPI_FILE} from ${JENKINS_MASTER_POD}'; \
            fi"
        # Install new plugins
        kubectl cp ${HPI_FILE} ${JENKINS_MASTER_POD}:${JENKINS_HOME}/plugins && echo "${HPI_FILE} transferred to ${JENKINS_MASTER_POD}"
        rm ${HPI_FILE}
    else
        echo "Error: Could not download ${HPI_FILE} @ ${PLUGIN_URL}"
    fi
done

# This creates a new pod and terminates the currently running pod, so plugins are forced to reload.
# TODO: A better alternative would be to do a safe restart of Jenkins since we need to make sure jobs are not interrupted.
kubectl patch deployment jenkins-master -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"$(date +%s)\"}}}}}"