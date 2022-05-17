# configTools

# rsyslog
# configRsyslog
## client
### 1, ready log fileslist
`cd rsyslog`
`ls /opt/bridge/logs/*log > logFilesList`
```(The file is an absolute path)```
### 2, config server
`vim ./configRsyslog-client.sh`
```remoteIPPORT="127.0.0.1:12345"```
### 3, run
`./configRsyslog-client.sh`
