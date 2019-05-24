#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export speedup_`

# remove dbus data in softcenter
confs=`dbus list speedup_|cut -d "=" -f1`
for conf in $confs
do
	dbus remove $conf
done


# remove files
rm -rf $KSROOT/bin/speedup*
rm -rf $KSROOT/scripts/uninstall_speedup*
rm -rf $KSROOT/scripts/speedup*
rm -rf $KSROOT/init.d/S86speedup.sh
rm -rf /etc/rc.d/S86speedup.sh >/dev/null 2>&1
rm -rf $KSROOT/webs/Module_speedup.asp
rm -rf $KSROOT/webs/res/icon-speedup.png
rm -rf $KSROOT/webs/res/icon-speedup-bg.png
rm -rf /tmp/upload/speedup_log.txt

# remove skipd data of qiandao
dbus remove softcenter_module_speedup_home_url
dbus remove softcenter_module_speedup_install
dbus remove softcenter_module_speedup_md5
dbus remove softcenter_module_speedup_version
dbus remove softcenter_module_speedup_name
dbus remove softcenter_module_speedup_title
dbus remove softcenter_module_speedup_description
