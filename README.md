# TSD dataportal import
Upload to TSD dataportal on command line

## Quick start

```
usage: tsdimport.sh -u user [-p project] [-g group] file
 -u username TSD username
 -p project  TSD project
 -g group    TSD group; default: pXX-member-group
 remove '/tmp/USERNAME_jwt' to reauthenticate
```

Uploads to `https://data.tsd.usit.no/v1/${project}/files/stream/${inputfilename}?group=${group}`
