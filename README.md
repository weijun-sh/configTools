# configTools

## rsyslog
### client
`git clone https://github.com/weijun-sh/configTools.git`  
`cd configTools`
### 1, ready log fileslist
`cd rsyslog`  
`ls /opt/bridge/logs/*log > logFilesList`  
```(The file is an absolute path)```  
### 2, config server
`vim ./configRsyslog-client.sh`  
```servrIP="127.0.0.1"```  
```port="12345"```  
### 3, run
`./configRsyslog-client.sh`  
