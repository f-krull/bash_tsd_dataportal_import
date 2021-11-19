#!/usr/bin/env bash 

set -ETeuo pipefail

# requirements
# - base64
# - jq


# TODO:
#  support dirs?
#  multiple files/dirs as agruments
#  reauth after token expires


jwtfile=/tmp/USERNAME_jwt

usage() {
  printf "usage: $(basename $0) -u user [-p project] [-g group] file\n"
  printf "  remove '${jwtfile}' to reauthenticate\n"
}

argument_error() {
  printf "error: missing arguments\n\n" >&2
  usage
  exit 1;
}

inp_group=
inp_username=
inp_project=

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -u|--username)
      [ ! -z ${2+x} ] || argument_error
      inp_username=$2
      shift
      shift
      ;;
    -g|--group)
      [ ! -z ${2+x} ] || argument_error
      inp_group=$2
      shift
      shift
      ;;
    -p|--project)
      [ ! -z ${2+x} ] || argument_error
      inp_project=$2
      shift
      shift
      ;;
    *)
      break
  esac
done

[ ! -z ${inp_username} ] || { printf "error: missing user name\n\n" >&2; usage; exit 1; }

# config
username=${inp_username}
project=${inp_project}
: ${project:=${username%%-*}} # derive project by taking pXXX-username prefix
group=${inp_group}
: ${group:="${project}-member-group"} # derive project by taking pXXX-username prefix


# echo "username:" $username
# echo "project:" $project
# echo "group:" $group

jwtfile=/tmp/${username}_jwt

[ ! -z ${1+x} ] || { printf "error: missing arguments\n\n" >&2; usage; exit 1; }

inputfilepath=${1}
inputfilename=${inputfilepath##*/}

[ -f "${inputfilepath}" ] || { printf "error: file \"${inputfilepath}\" does not exists.\n" >&2; exit 1; }


# request access token?
if [ ! -f ${jwtfile} ]; then
  echo -n Password: 
  read -s password
  echo
  read -p "OTP:" otp

  reqdata=$(cat << EOF
{
  "user_name":"${username}",
  "password":"${password}",
  "otp":"${otp}"
}
EOF
)
  echo "$reqdata"
  jwt="$(
    curl "https://data.tsd.usit.no/${project}/import" \
    -X POST \
    -H 'Content-Type: application/json' \
    --data-raw "${reqdata}" \
    -v
  )"
  echo $jwt
  # check response
  { echo "${jwt}" | jq -e 'has("token")'; } || { printf "error: couldn't get access token\n\n" >&2; exit 1; }
  # write token file
  echo "${jwt}" | jq --raw-output .token > ${jwtfile}
fi

# upload file 
jwt="$( cat ${jwtfile} )"
r="$(
  curl "https://data.tsd.usit.no/v1/${project}/files/stream/${inputfilename}?group=${group}" \
    -X PUT \
    -H "Authorization: Bearer $jwt" \
    -H 'Cookie: import=' \
    --data-binary "@${inputfilepath}" \
    -v
  )"
echo "$r"
# check response
{ echo "${r}" | jq -e '.message | test("data streamed")'; } || { printf "error: couldn't upload file\n\n" >&2; exit 1; }

echo
