#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export speedup_`

sed -i '/mirrors.ustc.edu.cn/d' /etc/hosts
echo '218.104.71.170 mirrors.ustc.edu.cn' >> /etc/hosts
opkg update && opkg install bash &
mkdir -p $KSROOT/init.d
mkdir -p /tmp/upload

# remove old files if exist
find $KSROOT/init.d/ -name *speedup.sh* | xargs rm -rf
find /etc/rc.d/ -name *speedup.sh* | xargs rm -rf

cp -rf /tmp/speedup/* $KSROOT/
cp -rf /tmp/speedup/uninstall.sh $KSROOT/scripts/uninstall_speedup.sh

chmod +x $KSROOT/scripts/speedup_*
chmod +x $KSROOT/init.d/S86speedup.sh
ln -s $KSROOT/init.d/S86speedup.sh /etc/rc.d/
rm -rf $KSROOT/install.sh

# add icon into softerware center
dbus set softcenter_module_speedup_install=1
dbus set softcenter_module_speedup_name=speedup
dbus set softcenter_module_speedup_title=天翼云盘提速
dbus set softcenter_module_speedup_description="为宽带提速而生！！！"
dbus set softcenter_module_speedup_version=2.1.1

return 0
