#!/bin/bash 
set +x

#Create directories if they do not exist

echo "Creating config directories if they do not exist.."

org=openenclave-ci

# Get all build config types
build_configs=$(yq r $PWD/config.yml build-configs)

for build_config in $build_configs
do
    # Get all supported repos
    repos=$(yq r $PWD/config.yml repos)
    # Generate $build_config...
    for repo in $repos
    do
        echo "Creating $repo config directories if they do not exist.."

        mkdir "$PWD/$repo" -p

        echo "Get templates for $repo.."
        
        headers=$(cat $PWD/templates/headers/$build_config.yml)
        echo "$headers" > $PWD/$repo/$repo-$build_config.yaml

        if [ "$build_config" = "pre-submits" ] || [ "$build_config" = "postsubmits" ] 
        then
            echo "  ${org}/${repo}:" >> $PWD/$repo/$repo-$build_config.yaml
        fi

        operating_systems=$(yq r $PWD/config.yml $repo.operating-systems)
        for operating_system in $operating_systems
        do
            
            build_modes=$(yq r $PWD/config.yml $repo.build-modes)
            for build_mode in $build_modes
            do

                build_types=$(yq r $PWD/config.yml $repo.build-types)
                for build_type in $build_types
                do

                    compilers=$(yq r $PWD/config.yml $repo.compilers)
                    for compiler in $compilers
                    do

                        # Shorten for to keep within 63 prow job char limit
                        if [ "$compiler" = "clang-7" ]
                        then
                            compiler_short=c-7
                        elif [ "$compiler" = "clang-8" ]
                        then
                            compiler_short=c-8
                        else
                            compiler_short=$compiler
                        fi

                        # New line seems to not work 100% of the time, just for readability
                        echo $'' >> $PWD/$repo/$repo-$build_config.yaml

                        if [ "$build_mode" = "simulation" ]
                        then
# TODO: Not evaluating correctly, seems the tabs are being injected into the job config which is not what we want,
# as it negatively effects user readability.
eval "cat <<EOF
$(<$PWD/templates/general/$build_config.yml)        
EOF
" >> $PWD/$repo/$repo-$build_config.yaml
                    else
eval "cat <<EOF
$(<$PWD/templates/general/acc/$build_config.yml)        
EOF
" >> $PWD/$repo/$repo-$build_config.yaml
                        fi
                    done
                done
            done
        done 
    done
done
