#!/bin/bash
#
#本脚本是将memcache库配置到php中
#请确保当前环境已经安装php
#本脚本使用的php版本是php5，请根据环境修改变量即可。
#
#   exit code  
# exit 29 tar file error
# exit 30 configure error
# exit 31 make error
# exit 32 make install error
# exit 33 php_configure sed error

NULL=/dev/null
MEMCACHE_TAR="memcache-2.2.5.tgz"
MEMCACHE_DIR="memcache-2.2.5"
PHP_INSED_DIR="/usr/local/php5/"

test_yum () {
	yum clean all &> $NULL
	repolist=$(yum repolist | awk  '/repolist:.*/{print $2}' | sed 's/,//')
	if [ $repolist -gt 0 ];then
		return 0
	fi
	return 1
}

print_info () {
	if [ -n "$1" ] && [ -n "$2" ] ;then
		case "$2" in 
		OK)
			echo -e "$1 \t\t\t \e[32;1m[OK]\e[0m"
			;;
		Fail)
			echo -e "$1 \t\t\t \e[31;1m[Fail]\e[0m"
			;;
		*)
			echo "Usage info {OK|Fail}"
		esac
	fi
}

rotate_line(){
	INTERVAL=0.1
	TCOUNT="0"
	while :
	do
		TCOUNT=`expr $TCOUNT + 1`
		case $TCOUNT in
		"1")
			echo -e '-'"\b\c"
			sleep $INTERVAL
			;;
		"2")
			echo -e '\\'"\b\c"
			sleep $INTERVAL
			;;
		"3")
			echo -e "|\b\c"
			sleep $INTERVAL
			;;
		"4")
			echo -e "/\b\c"
			sleep $INTERVAL
			;;
		*)
			TCOUNT="0";;
		esac
	done
}

## $1 应该传入前一个命令的$?.$2为之前操作的名称,$3为出现错误时推出的参数
result_info () {
	#if [ $1 != [0-9] ] && [ "$2" -n ] && [ "$3" -n ] ;then
	
		if [ "$1" -eq 0 ];then
			print_info "$2" "OK"
		elif [ "$1" -ne 0 ];then
			print_info "$2" "Fail"
			exit "$3"
		else
			exit 35
		fi
	#fi
}


test_yum
if [ $? -ne 0 ];then
  print_info "yum error." "Fail"
  exit 30
fi

rotate_line &
disown $!
yum -y install gcc* > $NULL
result=$?
kill -9 $!

if [ -f $MEMCACHE_TAR ];then
	tar -xf $MEMCACHE_TAR
	cd $MEMCACHE_DIR
	${PHP_INSED_DIR}bin/phpize .
	if [ -f configure ];then
		rotate_line &
		disown $!
		./configure  --with-php-config=${PHP_INSED_DIR}bin/php-config --enable-memcache &>$NULL
		result=$?
		result_info $result "configure"  "31"
		make > $NULL
		result_info $? "make" "31"
		make install > $NULL
		result_info $? "make install" "31"
		kill -9 $!
	else 
		print_info "cofigure no such file." "Fail"
		exit 32
	fi
else 
	print_info "install tar file no such file." "Fail"
	exit 29
fi

##
grep  "${PHP_INSED_DIR}lib/php/extensions/no-debug-non-zts-20100525/" ${PHP_INSED_DIR}etc/php.ini > $NULL
if [ $? -ne 0 ];then
	sed -i '728i extension_dir = "${PHP_INSED_DIR}lib/php/extensions/no-debug-non-zts-20100525/"' ${PHP_INSED_DIR}etc/php.ini
fi

grep "extension=memcache.so" ${PHP_INSED_DIR}etc/php.ini  > $NULL

if [ $? -ne 0 ];then
	sed -i '856i extension=memcache.so' ${PHP_INSED_DIR}etc/php.ini
fi
