#!/usr/bin/env bash 

set -ETeuo pipefail

# requirements
# - base64
# - jq


# TODO:
#  support dirs?
#  multiple files/dirs as agruments
#  -u -g -p (user/group/project)
#  derive project from user
#  derive group from project

# config
project="p22"
username="${project}-floriakr"
group="${project}-member-group"
jwtfile=/tmp/${username}_jwt

inputfilepath=${1}
inputfilename=${inputfilepath##*/}

if [ ! -f "${inputfilepath}" ]; then
  printf "usage: $(basename $0) <file>\n\n"
  printf "remove '${jwtfile}' to reauthenticate\n"
  exit 1
fi

# request access token?
if [ ! -f ${jwtfile} ]; then
  echo -n Password: 
  read -s password
  echo
  read -p "OTP:" otp

  read -d '' reqdata << EOF
{
  "user_name":"${username}",
  "password":"${password}",
  "otp":"${otp}"
}
EOF
  echo "$reqdata"
  jwt="$(
    curl "https://data.tsd.usit.no/${project}/import" \
    -X POST \
    -H 'Content-Type: application/json' \
    --data-raw "${reqdata}"
  )"
  echo "${jwt}" | jq --raw-output .token > ${jwtfile}
fi

# print access token
echo "$jwt"

# upload file 
jwt="$( cat ${jwtfile} )"
curl "https://data.tsd.usit.no/v1/${project}/files/stream/${inputfilename}?group=${group}" \
  -X PUT \
  -H "Authorization: Bearer $jwt" \
  -H 'Cookie: import=' \
  --data-binary "@${inputfilepath}" \
  -v

echo
