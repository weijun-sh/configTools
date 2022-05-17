#!/bin/sh
serverIP=""
port=""
logFiles=logFilesList

configFile=/etc/rsyslog.conf
configFileDefault=/etc/rsyslog.d/50-default.conf
localName=local0

serverIPPORT=$serverIP:$port

argsCount=$#
countLog=0
restartRsyslog=0

checkIP(){
	if [ "$serverIP" = "" ] || [ "$port" = "" ];then
		echo "Please add serverIP or port to $0"
		exit
	fi
	serverIPPORT=$serverIP:$port
}

#check rsyslog version and config file
checkRsyslog(){
	rsyslogd -v > /dev/null
	if [ $? != 0 ];then
		echo "Please install rsyslog\nExamp: apt install rsyslog"
		exit
	fi
}

usage(){
	echo "Usage:"
	echo "\t$0"
	echo "\t$0 list"
	echo "\t$0 remove"
}

checkLog(){
	if [ -d "$1" ];then
		echo "\tERR | args1 '$1' is dir, must be file"
		return 1
	fi
	if [ ! -f "$1" ] || [ ! -e "$1" ];then
		echo "\tERR | logFile '$1' not exist"
		return 1
	fi
	echo "OK"
}
checkOp(){
	if [ "$1" != "list" ] && [ "$1" != "update" ];then
		echo "ERR | args1 '$1' not support!"
		usage
		exit
	fi
}

# $#
checkArgs(){
	echo "1/3 - check args"
	if [ $argsCount = 1 ];then
		checkOp $1
		echo "\tOK"
	else
		if [ $argsCount != 0 ];then
			usage
			exit
		fi
		echo "\tOK"
	fi
}

checkDefault(){
	echo "3/3 - check $configFileDefault"
	grep "$localName.none" $configFileDefault > /dev/null
	if [ $? = 0 ];then
		echo "\tOK"
	else
		grep "^\*.\*" $configFileDefault > /dev/null
		if [ $? != 0 ];then
			echo "ERR | $configFileDefault is unrecognizable"
			exit
		fi
		ret=`grep "^\*.\*" $configFileDefault|sed "s/\t/ /g"`
		retreplace=`echo ${ret% *}`
		#echo "$retreplace"
		sed -i "s#$retreplace#$retreplace;$localName.none#g" $configFileDefault
		echo "\tUpdate | $retreplace;$localName.none"
	fi
}

checkConfig(){
	echo "2/3 - check $configFile"
	grepStr="# provides kernel logging support and enable non-kernel klog messages"
	grep "$grepStr" $configFile >/dev/null
	if [ $? != 0 ];then
		echo "ERR | $configFileDefault is unrecognizable"
		exit
	fi
	grep "module(load=\"imfile\" PollingInterval" $configFile >/dev/null
	if [ $? != 0 ];then
		sed -i "/$grepStr/i\module(load=\"imfile\" PollingInterval=\"10\")" $configFile
		echo "\tOK  | module(load="imfile" PollingInterval="10")"
		((restartRsyslog++))
	fi
	grep "^$localName.\* @$serverIPPORT" $configFile >/dev/null
	if [ $? != 0 ];then
		sed -i "/$grepStr/i\\$localName.* @$serverIPPORT" $configFile
		echo "\tOK  | $localName.* @$serverIPPORT"
		((restartRsyslog++))
	fi
	while read line
	do
		#echo "$line"
		ret=`checkLog $line`
		if [ "$ret" != "OK" ];then
			echo "$ret"
			continue
		fi
		logFile=`realpath $line`
		grep "type=\"imfile\" File=\"$logFile\"" $configFile >/dev/null
		if [ $? != 0 ];then
			tag=`echo ${logFile##*/}`
			#echo "tag, $tag"
			sed -i "/$localName.\* @$serverIPPORT/i\input(type=\"imfile\" File=\"$logFile\" Tag=\"$tag\" Severity=\"info\" Facility=\"$localName\" freshStartTail=\"on\" deleteStateOnFileDelete=\"on\")" $configFile
			echo "\tOK  | input(type=\"imfile\" File=\"$logFile\" Tag=\"$tag\" Severity=\"info\" Facility=\"$localName\" freshStartTail=\"on\" deleteStateOnFileDelete=\"on\")"
			((countLog++))
			((restartRsyslog++))
		else
			echo "\tINFO| logFile '$line'($logFile) config exist"
		fi
	done < $logFiles
	echo "\tOK"
}

# ========== start ==========
checkRsyslog
checkIP
echo "config rsyslog client"
echo

checkArgs $1
checkConfig
checkDefault
echo "\nrsyslog add $countLog file(s)"

if [ $restartRsyslog != 0 ];then
	systemctl restart rsyslog
fi
