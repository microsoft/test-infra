#!/bin/bash 
set +x

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

# load builttype maps into memory
buildtypes=$(yq r $PWD/config.yml buildtype)
declare -A buildtypemap
for buildtype in $buildtypes
do
    buildtypemaps=$(yq r $PWD/config.yml buildtypemap.$buildtype)
    for buildtypekey in $buildtypemaps
    do
        buildtypemap["$buildtypekey"]="$buildtype"
        echo "$buildtypekey maps to - > ${buildtypemap[$buildtypekey]}"
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

# load windowsversionmap into memory
windowsversions=$(yq r $PWD/config.yml windowsversions)
declare -A windowsversionmap
for windowsversion in $windowsversions
do
    windowsversionsmap=$(yq r $PWD/config.yml windowsversionsmap.$windowsversion)
    for windowsversionkey in $windowsversionsmap
    do
        windowsversionmap["$windowsversionkey"]="$windowsversion"
        echo "$windowsversionkey maps to - > ${windowsversionmap[$windowsversionkey]}"
    done
done

# load snmallocmap into memory
snmallocoptions=$(yq r $PWD/config.yml snmallocoptions)
declare -A snmallocmap
for snmallocoption in $snmallocoptions
do
    snmallocmaps=$(yq r $PWD/config.yml snmallocmap.$snmallocoption)
    for snmallockey in $snmallocmaps
    do
        snmallocmap["$snmallockey"]="$snmallocoption"
        echo "$snmallockey maps to - > ${snmallocmap[$snmallockey]}"
    done
done

# load buildmodemap into memory
buildmodes=$(yq r $PWD/config.yml buildmodes)
declare -A buildmodemap
for buildmode in $buildmodes
do
    buildmodemaps=$(yq r $PWD/config.yml buildmodesmap.$buildmode)
    for buildmodekey in $buildmodemaps
    do
        buildmodemap["$buildmodekey"]="$buildmode"
        echo "$buildmodekey maps to - > ${buildmodemap[$buildmodekey]}"
    done
done

# load lvimap into memory
lvioptions=$(yq r $PWD/config.yml lvioptions)
declare -A lvimap
for lvioption in $lvioptions
do
    lvioptionsmaps=$(yq r $PWD/config.yml lvioptionsmaps.$lvioption)
    for lvikey in $lvioptionsmaps
    do
        lvimap["$lvikey"]="$lvioption"
        echo "$lvikey maps to - > ${lvimap[$lvikey]}"
    done
done

# Get repo name
repos=$(yq r $PWD/config.yml repos)

build_configs=$(yq r $PWD/config.yml build-configs)

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
