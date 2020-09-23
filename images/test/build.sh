#!/usr/bin/env bash

# Exit immediately on error
set -e

##====================================================================================
##
## Docker Image Wrapper
##
##====================================================================================
if [[ $1 == "-h" || $1 == "--help" ]]; then
   echo "Script wrapper to build docker images"
   echo " Usage: "
   echo " ./images/test/build.sh"
   echo "        -h or --help to Display usage and exit"
   echo "        --docker_user path to docker file"
   echo "        --docker_pass path to docker file"
   echo "        --docker_path path to docker file"
   echo "        --docker_tag custom tag to use"
   echo "        --skip_testing disable testing of the image"
   echo ""
   exit 0
fi

# Build Docker Image. Why are you here if you are overwriting this?!
BUILD=1
# Test  Docker Image. Default is enabled
TEST=1
# Publish Docker Image. Default is disabled.
PUSH=0
# Tag
TAG="image:latest"
DOCKER_PATH=""

# Hack to allow scripts to run locally and in a container
if ! [ -f /.dockerenv ]; then
    echo SUDO=sudo
fi

# Parse the command line - keep looping as long as there is at least one more argument
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in
        # This is a flag type option. Will catch --docker_user 
        --docker_user)
        shift # past the key and to the value
        DOCKER_USER=$1
        ;;
        # This is a flag type option. Will catch --docker_user 
        --docker_pass)
        shift # past the key and to the value
        DOCKER_PASS=$1
        ;;
        # This is a flag type option. Will catch --docker_path 
        --docker_path)
        shift # past the key and to the value
        DOCKER_PATH=$1
        ;;
        # This is a flag type option. Will catch --docker_tag 
        --docker_tag)
        shift # past the key and to the value
        TAG=$1
        ;;
        # This is a flag type option. Will catch --docker_tag 
        --skip_testing)
        TEST=0
        ;;
        # This is a flag type option. Will catch --docker_push 
        --docker_push)
        PUSH=1
        ;;
        *)
        echo "Unknown option '${key}'"
        exit 1
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

if [[ ${BUILD} -eq 1 ]]; then
    ${SUDO} docker build . -f ${DOCKER_PATH} -t ${TAG} --no-cache
fi

if [[ ${TEST} -eq 1 ]]; then
    ${SUDO} docker run ${TAG} bash -c "./images/test/validate.sh" 
fi

if [[ ${PUSH} -eq 1 ]]; then
    # TODO https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
    ${SUDO} docker login --username=$DOCKER_USER --password=$DOCKER_PASS
    ${SUDO} docker push ${TAG}
fi
