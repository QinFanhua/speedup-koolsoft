#!/bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export speedup_`
logfile="/tmp/upload/speedup_log.txt"
ACTION=$1
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
scriptpath=$(cd "$(dirname "$0")"; pwd)
scriptname=$(basename $0)

speedup_path="/koolshare/bin/speedup"

[ -z $speedup_enable ] && speedup_enable=0

if [ "$speedup_enable" != "0" ] ; then
    http_response '设置已保存！正在启动提速！！页面将在1秒后刷新！！！'
	SN=""
	AccessToken="$(echo $speedup_AccessToken | base64_decode)"
	qosClientSn="$(cat /proc/sys/kernel/random/uuid)"
else
	http_response '设置已保存！正在关闭提速！！页面将在1秒后刷新！！！'
fi

speedup_restart () {

speedup_renum=`dbus get speedup_renum`
relock="/var/lock/speedup_restart.lock"
if [ "$1" = "o" ] ; then
	dbus set speedup_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
	    echo $(date +%Y年%m月%d日\ %X) "【speedup】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动" >> $logfile 2>&1
		exit 0
	fi
	speedup_renum=${speedup_renum:-"0"}
	speedup_renum=`expr $speedup_renum + 1`
	dbus set speedup_renum="$speedup_renum"
	if [ "$speedup_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		echo $(date +%Y年%m月%d日\ %X) "【speedup】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动" >> $logfile 2>&1
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(dbus get speedup_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		dbus set speedup_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
dbus set speedup_status=0
eval "$scriptfilepath &" &
exit 0
}

speedup_get_status () {

A_restart=`dbus get speedup_status`
B_restart="$speedup_enable$AccessToken"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	dbus set speedup_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

speedup_check () {

speedup_get_status
if [ "$speedup_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$speedup_path" | grep -v grep )" ] && echo $(date +%Y年%m月%d日\ %X) "【speedup】" "停止 speedup" >> $logfile 2>&1 && speedup_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$speedup_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		speedup_close
		speedup_start
	else
		[ -z "$(ps -w | grep "$speedup_path" | grep -v grep )" ] && speedup_restart
	fi
fi
}

speedup_keep () {
echo $(date +%Y年%m月%d日\ %X) "【speedup】" "守护进程启动" >> $logfile 2>&1
sleep 60
speedup_enable=`dbus get speedup_enable`
i=1
while [ "$speedup_enable" = "1" ]; do
	NUM=`ps -w | grep "$speedup_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$speedup_path" ] || [ "$i" -ge 369 ] ; then
		echo $(date +%Y年%m月%d日\ %X) "【speedup】" "重新启动$NUM" >> $logfile 2>&1
		speedup_restart
	fi
sleep 69
i=$((i+1))
speedup_enable=`dbus get speedup_enable`
done
}

speedup_close () {
dbus set speedup_dialAccount=""
dbus set speedup_downQosRate=""
dbus set speedup_downRate=""
dbus set speedup_sn=""
dbus set speedup_upQosRate=""
dbus set speedup_upRate=""
rm -rf /tmp/upload/speedup_log.txt
killall speedup
killall -9 speedup
eval $(ps -w | grep "speedup start_path" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "speedup.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

speedup_start () {

[ -z "$AccessToken" ] && echo $(date +%Y年%m月%d日\ %X) "【speedup】" "错误！！！【AccessToken代码】未填写" >> $logfile 2>&1  && sleep 10 && exit

curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	echo $(date +%Y年%m月%d日\ %X) "【speedup】" "找不到 curl ，需要手动安装" >> $logfile 2>&1
	
	echo $(date +%Y年%m月%d日\ %X) "【speedup】" "启动失败, 10 秒后自动尝试重新启动" >> $logfile 2>&1  && sleep 10 && speedup_restart x
fi

speedup_vv=2019-5-20
speedup_v=$(grep 'speedup_vv=' /koolshare/scripts/speedup_config.sh | grep -v 'speedup_v=' | awk -F '=' '{print $2;}')
echo $(date +%Y年%m月%d日\ %X) "【speedup】" "运行 $speedup_path" >> $logfile 2>&1
ln -sf /koolshare/scripts/speedup_config.sh /koolshare/bin/speedup
chmod 777 /koolshare/bin/speedup
eval "$speedup_path" start_path &
sleep 2
[ ! -z "$(ps -w | grep "/koolshare/bin/speedup" | grep -v grep )" ] && echo $(date +%Y年%m月%d日\ %X) "【speedup】" "启动成功 $speedup_v " >> $logfile 2>&1 && speedup_restart o
[ -z "$(ps -w | grep "/koolshare/bin/speedup" | grep -v grep )" ] && echo $(date +%Y年%m月%d日\ %X) "【speedup】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" >> $logfile 2>&1 && sleep 10 && speedup_restart x

speedup_get_status
eval "$scriptfilepath keep &" &

}

speedup_start_path () {

[ -z "$SN" ] && SN=0
speedup_enable=`dbus get speedup_enable`

[ -z $speedup_enable ] && speedup_enable=0 && dbus set speedup_enable=0
while [[ "$speedup_enable" != 0 ]] 
do
	if [ "$SN"x == "0"x ] || [ -z "$SN"  ]; then
		echo $(date +%Y年%m月%d日\ %X) "【speedup】" "Start_SN is $SN, need to Speedup now" >> $logfile 2>&1
		get_session && QOS_Check && QOS_Start
		if [[ -z "$SN" ]]; then
			echo $(date +%Y年%m月%d日\ %X) "【speedup】" "Start_ERROR!!!" >> $logfile 2>&1
		else
			echo $(date +%Y年%m月%d日\ %X) "【speedup】" "Start Speedup, SN: $SN" >> $logfile 2>&1
			sleep 597
		fi
	fi
	if [[ ! -z "$SN" ]]; then
		QOS_Start
		echo $(date +%Y年%m月%d日\ %X) "【speedup】" "Keep  Speedup, SN: $SN" >> $logfile 2>&1
		sleep 597
	fi
	speedup_enable=`dbus get speedup_enable`
	[ -z $speedup_enable ] && speedup_enable=0 && dbus set speedup_enable=0
done

}

hashHmac() {
    digest="$1"
    data="$2"
    key="$3"
    echo -n "$data" | openssl dgst "-$digest" -hmac "$key" | sed -e 's/^.* //' | tr 'a-z' 'A-Z'
}

get_session()
{

speedup_login="curl -s --connect-timeout 15 -m 15 http://api.cloud.189.cn/loginByOpen189AccessToken.action?accessToken=""$AccessToken"" -H 'User-Agent:Apache-HttpClient/UNAVAILABLE(java1.4)'"

re_STAT="$(eval "$speedup_login" | grep userSession)"

session_Key="$(echo "$re_STAT" | grep -Eo "sessionKey>.*</sessionKey" | sed 's/<\/sessionKey//' | sed 's/sessionKey>//' )"

session_Secret="$(echo "$re_STAT" | grep -Eo "sessionSecret>.*</sessionSecret" | sed 's/sessionSecret>//' | sed 's/<\/sessionSecret//' )"

}

get_info()
{

dial_Account="$(echo "$re_STAT" | awk -F"\<dialAccount\>|\<\/dialAccount\>" '{if($2!="") print $2}')"
dbus set speedup_dialAccount="$dial_Account"

base_Down="$(echo "$re_STAT" | awk -F"\<baseDownRate\>|\<\/baseDownRate\>" '{if($2!="") print $2}')"
base_DownRate=$(($base_Down/1024))
dbus set speedup_downRate="$base_DownRate"

base_Up="$(echo "$re_STAT" | awk -F"\<baseUpRate\>|\<\/baseUpRate\>" '{if($2!="") print $2}')"
base_UpRate=$(($base_Up/1024))
dbus set speedup_upRate="$base_UpRate"

target_Down="$(echo "$re_STAT" | awk -F"\<targetDownRate\>|\<\/targetDownRate\>" '{if($2!="") print $2}')"
target_DownRate=$(($target_Down/1024))
dbus set speedup_downQosRate="$target_DownRate"

target_Up="$(echo "$re_STAT" | awk -F"\<targetUpRate\>|\<\/targetUpRate\>" '{if($2!="") print $2}')"
target_UpRate=$(($target_Up/1024))
dbus set speedup_upQosRate="$target_UpRate"

echo $(date +%Y年%m月%d日\ %X) "【speedup】" "宽带账号【$dial_Account】 下行速率【$target_DownRate"M"】 上行速率【$target_UpRate"M"】" >> $logfile 2>&1

}

QOS_Check()
{
GMT_Date="$(date -u '+%a, %d %b %Y %T GMT')"

ACCESS_URL="/speed/checkSpeedAbilityV2.action"

data="SessionKey=$session_Key&Operate="GET"&RequestURI=$ACCESS_URL&Date=$GMT_Date"

key="$session_Secret"

Check_Signature=`hashHmac "sha1" "$data" "$key"`

Check_Qos="curl -s --connect-timeout 15 -m 15 http://api.cloud.189.cn/speed/checkSpeedAbilityV2.action?qosClientSn=""$qosClientSn"" -H 'SessionKey:""$session_Key""' -H 'Signature: ""$Check_Signature""' -H 'Date: ""$GMT_Date""' -H 'User-Agent:Apache-HttpClient/UNAVAILABLE(java1.4)'"             

re_STAT="$(eval "$Check_Qos" | grep qosCheckResponse)"

get_info

sleep 3
}

QOS_Start()
{
GMT_Date="$(date -u '+%a, %d %b %Y %T GMT')"

ACCESS_URL="/speed/startSpeedV2.action"

data="SessionKey=$session_Key&Operate="GET"&RequestURI=$ACCESS_URL&Date=$GMT_Date"

key="$session_Secret"

Start_Signature=`hashHmac "sha1" "$data" "$key"`

Start_Qos="curl -s --connect-timeout 15 -m 15 http://api.cloud.189.cn/speed/startSpeedV2.action?qosClientSn=""$qosClientSn"" -H 'SessionKey:""$session_Key""' -H 'Signature: ""$Start_Signature""' -H 'Date: ""$GMT_Date""' -H 'User-Agent:Apache-HttpClient/UNAVAILABLE(java1.4)'"

SN_STAT="$(eval "$Start_Qos" | grep qosInfoResponse)"

SN="$(echo "$SN_STAT" | awk -F"\<qosSn\>|\<\/qosSn\>" '{if($2!="") print $2}')"
dbus set speedup_sn="$SN"
sleep 3
}

case $ACTION in
start)
	dbus set speedup_status=0
	speedup_close
	speedup_check
	;;
check)
	speedup_check
	;;
stop)
	speedup_close
	;;
keep)
	speedup_keep
	;;
start_path)
	speedup_start_path
	;;
*)
	speedup_check
	;;
esac