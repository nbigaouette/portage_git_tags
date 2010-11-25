#!/bin/bash

# Copyright 2010 Nicolas Bigaouette <nbigaouette @t gmail com>
# This file is part of portage_git_tags
# http://github.com/nbigaouette/portage_git_tags
#
# portage_git_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# portage_git_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with git-scripts. If not, see <http://www.gnu.org/licenses/>.

local_portage_dir="portage"

# rsync_mirror="rsync://gentoo.gossamerhost.com/gentoo-distfiles/"
# rsync_mirror="rsync://rsync.ca.gentoo.org"
rsync_mirror="rsync://rsync.gentoo.org/gentoo-portage"
PORTAGE_RSYNC_OPTS="--recursive --links --safe-links --perms --times --compress --force --whole-file --delete --stats --timeout=180 --exclude=/distfiles --exclude=/local --exclude=/packages"

mirror="http://gentoo.arcticnetwork.ca"
portage_snapshot_path="snapshots"
portage_snapshot_file="portage-latest.tar.bz2"

now=`date +%Y%m%d_%Hh%M`

function die()
{
    echo -e "${@}"
    exit
}

function get_latest_portage_snapshot()
{
    if [[ ${#@} -ne 4 ]]; then
        die "ERROR: get_latest_portage_snapshot() function takes exactly 4 arguments!\nCurrent arguments: ${@}"
    fi
    mirror="${1}"
    portage_snapshot_path="${2}"
    portage_snapshot_file="${3}"
    local_portage_dir="${4}"
#     [[ -e ${portage_snapshot_file} ]] && rm -f ${portage_snapshot_file}*
#     wget ${mirror}/${portage_snapshot_path}/${portage_snapshot_file}
#     wget ${mirror}/${portage_snapshot_path}/${portage_snapshot_file}.gpgsig
#     wget ${mirror}/${portage_snapshot_path}/${portage_snapshot_file}.md5sum
    md5sum -c ${portage_snapshot_file}.md5sum || die "md5sum does not match!"

    # Remove old directories, extract new and move to wanted location
    [[ "${local_portage_dir}" != "portage" ]] && rm -fr portage
    rm -fr ${local_portage_dir}/*
    tar xjf ${portage_snapshot_file}
    [[ "${local_portage_dir}" != "portage" ]] && mv portage/* ${local_portage_dir}/
}

function rsync_portage()
{
    if [[ ${#@} -ne 3 ]]; then
        die "ERROR: rsync_portage() function takes exactly 2 arguments!\nCurrent arguments: ${@}"
    fi
    PORTAGE_RSYNC_OPTS="${1}"
    rsync_mirror="${2}"
    local_portage_dir="${3}"
    [[ -d ${local_portage_dir}/.git ]]  && mv ${local_portage_dir}/.git ./${local_portage_dir}_git
    rsync ${PORTAGE_RSYNC_OPTS} ${rsync_mirror} ${local_portage_dir}
    [[ -d ./${local_portage_dir}_git ]] && mv ./${local_portage_dir}_git ${local_portage_dir}/.git
}

function init_git_repo()
{
    if [[ ${#@} -ne 1 ]]; then
        die "ERROR: init_git_repo() function takes exactly 1 arguments!\nCurrent arguments: ${@}"
    fi
    cd ${local_portage_dir}
    if [[ ! -d .git ]]; then
        git init
    fi
    cd -
}

function sync_and_git_tag()
{
    # Sync local portage tree
    if [[ -d ${local_portage_dir} ]]; then
        # If directory already exists, use rsync to update
        echo "Directory ${local_portage_dir} already exists, updating using rsync..."
        rsync_portage "${PORTAGE_RSYNC_OPTS}" ${rsync_mirror} ${local_portage_dir}
    else
        # If directory does not exists, get a tarbal snapshot and extract
        echo "Directory ${local_portage_dir} does not exists, downloading tarbal and extracting..."
        get_latest_portage_snapshot ${mirror} ${portage_snapshot_path} ${portage_snapshot_file} ${local_portage_dir}
    fi

    init_git_repo ${local_portage_dir}

    cd ${local_portage_dir}
    nothing_to_commit=`git status | grep "nothing to commit"`
    if [[ "${nothing_to_commit}" == "nothing to commit (working directory clean)" ]]; then
        echo "No change since last sync, skipping tag."
    else
        # Add to git
        echo "Adding portage files to git repo..."
        git add *
        echo "Committing..."
        git commit -a -m "Automatic portage git commit - ${now}"
        echo "Tagging as \"${now}\"..."
        git tag ${now}
    fi
    cd -
}

# Run it!
sync_and_git_tag
