#!/bin/bash

skip_check_words="ignore check"

LOG_ERROR() {
    content=${1}
    echo -e "\033[31m"${content}"\033[0m"
}

LOG_INFO()
{
    local content=${1}
    echo -e "\033[32m[INFO] ${content}\033[0m"
}

function check_PR()
{
    if [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
        local skip=$(curl -s https://api.github.com/repos/vita-dounai/liquid-doc/pulls/${TRAVIS_PULL_REQUEST} | grep "title\"" | grep "${skip_check_words}")
        if [ ! -z "${skip}" ]; then
            LOG_INFO "skip PR check!"
            exit 0
        else
            LOG_INFO "PR-${TRAVIS_PULL_REQUEST}, checking PR..."
        fi
    fi
    local commits=$(git rev-list --count HEAD^..HEAD)
    local unique_commit=$(git log --format=%s HEAD^..HEAD | sort -u | wc -l)
    if [ ${unique_commit} -ne ${commits} ];then
        LOG_ERROR "${commits} != ${unique_commit}, please make commit message unique!"
        exit 1
    fi
}

check_PR
