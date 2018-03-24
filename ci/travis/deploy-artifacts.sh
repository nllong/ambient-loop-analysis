#!/usr/bin/env bash

# Method for joining array together with any separator (e.g. join_by , (a b c) ==> a,b,c)
function join_by { local IFS="$1"; shift; echo "$*"; }

if [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    if [ "${TRAVIS_BRANCH}" == "master" ]; then
        aws s3 cp --recursive ./python/output s3://openstudio-metamodels/small_office/release/
    elif [ "${TRAVIS_BRANCH}" == "develop" ]; then
        aws s3 cp --recursive ./python/output s3://openstudio-metamodels/small_office/latest/
    else
        aws s3 cp --recursive ./python/output s3://openstudio-metamodels/small_office/$TRAVIS_BUILD_NUMBER/
    fi
else
    # must be a pull request, post back to github
#    aws s3 cp --recursive ./python/output s3://openstudio-metamodels/small_office/${TRAVIS_BUILD_NUMBER}/

    model_str=()
    results=(python/output/*/models/)
    for result in "${results[@]}"
    do
        analysis_id=$(basename $(dirname ${result}))
        model_str+=("https://s3.amazonaws.com/openstudio-metamodels/small_office/${TRAVIS_BUILD_NUMBER}/${analysis_id}/models/models.zip")
    done

    echo "${model_str[@]}"
    help_url=https://github.com/nllong/ambient-loop-analysis/blob/${TRAVIS_BRANCH}/python/analyses.json

    github_body=$(cat << EOF
The built models for this PR are here:\n\n$(join_by ' , ' ${model_str[@]})\n\nDescription of the model covariates and responses can be found here:${help_url}
EOF
)

    curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
         -d "{\"body\": \"${github_body}\"}" \
         "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"

fi
