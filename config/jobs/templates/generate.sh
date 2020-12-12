#!/bin/bash 
set +x

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
        pipelines=$(yq r $PWD/config.yml $repo.pipelines)

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
        done
    done
done

