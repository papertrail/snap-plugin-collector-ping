#!/bin/bash -e

#http://www.apache.org/licenses/LICENSE-2.0.txt
#
#
#Copyright 2015 Intel Corporation
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

set -e
set -u
set -o pipefail

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__proj_dir="$(dirname "$__dir")"

# shellcheck source=scripts/common.sh
. "${__dir}/common.sh"

if [[ "${GOARCH}" == "amd64" ]]; then
  build_dir="${__proj_dir}/build/${GOOS}/x86_64/examples"
else
  build_dir="${__proj_dir}/build/${GOOS}/${GOARCH}/examples"
fi

plugin_src_path=$1
plugin_name=$(basename "${plugin_src_path}")
git_version=$(_git_version)
go_build=(go build -ldflags "-w -X main.gitversion=${git_version}")

if [[ "${GOOS}" == "windows" ]]; then
  plugin_name="${plugin_name}.exe"
fi

_info "git commit: $(git log --pretty=format:"%H" -1)"

# Disable CGO for builds.
export CGO_ENABLED=0

_debug "plugin source: ${plugin_src_path}"
_info "building ${plugin_name} for ${GOOS}/${GOARCH}"
_debug "running: ${go_build[@]} -o ${build_dir}/${plugin_name}"

(cd "${plugin_src_path}" && "${go_build[@]}" -o "${build_dir}/${plugin_name}" . || exit 1)
