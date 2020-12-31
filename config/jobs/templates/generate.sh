#!/bin/bash 
set +x

# Get repo name
repos=$(yq r $PWD/config.yml repos)

build_configs=$(yq r $PWD/config.yml build-configs)

# load jobmap into memory
jobs=$(yq r $PWD/config.yml jobs)
declare -A jobmap
for job in $jobs
do
    jobmaps=$(yq r $PWD/config.yml jobmaps.$job)
    for jobkey in $jobmaps
    do
        jobmap["$jobkey"]="$job"
        echo "$jobkey maps to - > ${jobmap[$jobkey]}"
    done
done

# load compilermap into memory
compilers=$(yq r $PWD/config.yml compilers)
declare -A compilermap
for compiler in $compilers
do
    compilermaps=$(yq r $PWD/config.yml compilermap.$compiler)
    for compilerkey in $compilermaps
    do
        compilermap["$compilerkey"]="$compiler"
        echo "$compilerkey maps to - > ${compilermap[$compilerkey]}"
    done
done

# load linuxversionmap into memory
linuxversions=$(yq r $PWD/config.yml linuxversions)
declare -A linuxversionmap
for linuxversion in $linuxversions
do
    linuxversionsmap=$(yq r $PWD/config.yml linuxversionsmap.$linuxversion)
    for linuxversionkey in $linuxversionsmap
    do
        linuxversionmap["$linuxversionkey"]="$linuxversion"
        echo "$linuxversionkey maps to - > ${linuxversionmap[$linuxversionkey]}"
    done
done

for repo in $repos
do
    # Create folders if DNE
    mkdir -p $PWD/../$repo
    # Generate each post/presub/periodic config
    for build_config in $build_configs
    do
        # Get Template headers and echo them to start
        headers=$(cat $PWD/../templates/headers/$build_config.yml)
        echo "$headers" > $PWD/../$repo/$repo-$build_config.yaml

        # Periodicals are mapped in a different way, deal with edge case to output which gh org/repo we need
        if [ "$build_config" = "pre-submits" ] || [ "$build_config" = "postsubmits" ] 
        then
            echo "  openenclave/${repo}:" >> $PWD/../$repo/$repo-$build_config.yaml
        fi
        pipelines=$(yq r $PWD/config.yml pipelines.$repo)

        # Generate each pipeline permutation
        for pipeline in $pipelines
        do
            echo "generating $repo $build_config $pipeline template"
            # New line seems to not work 100% of the time, just for readability
            echo $'' >> $PWD/../$repo/$repo-$build_config.yaml
            # Badly indexed due to weird evaluation..
eval "cat <<EOF
$(<$PWD/../templates/jenkins/$build_config.yml)        
EOF
" >> $PWD/../$repo/$repo-$build_config.yaml

            echo "generating test-infra $repo $build_config $pipeline template"
            # New line seems to not work 100% of the time, just for readability
            echo $'' >> $PWD/../test-infra/test-infra-$build_config.yaml
            # Badly indexed due to weird evaluation..
eval "cat <<EOF
$(<$PWD/../templates/test-infra/$build_config.yml)        
EOF
" >> $PWD/../test-infra/test-infra-$build_config.yaml

############ Generating DSLS
echo "generating $repo $build_config $pipeline template"
            # New line seems to not work 100% of the time, just for readability
            mkdir -p $PWD/../../jenkins/configuration/jobs/${repo}
            rm $PWD/../../jenkins/configuration/jobs/${repo}/${pipeline}.yml
            # Badly indexed due to weird evaluation..
eval "cat <<EOF
$(<$PWD/jenkins/jobs/${jobmap[$pipeline]}.yml)        
EOF
" >> $PWD/../../jenkins/configuration/jobs/${repo}/${pipeline}.yml

############ Generating Test-infra DSLS
            mkdir -p $PWD/../../jenkins/configuration/jobs/test-infra/${repo}
            rm $PWD/../../jenkins/configuration/jobs/test-infra/${repo}/${pipeline}.yml
            # Badly indexed due to weird evaluation..
eval "cat <<EOF
$(<$PWD/jenkins/jobs/test-infra/${jobmap[$pipeline]}.yml)           
EOF
" >> $PWD/../../jenkins/configuration/jobs/test-infra/${repo}/${pipeline}.yml
        done
    done
done
