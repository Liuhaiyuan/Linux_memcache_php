#!/bin/bash
# exit 29 tar file error
# exit 30 yum error
# exit 31 depending install error
# exit 32 confingure error
# exit 33 make error
# exit 34 make install error


# static variable
NULL=/dev/null
MEMCACHED_INTAR="memcached-1.4.24.tar.gz"
DEP_LIBEVENT="libevent-2.0.21-stable.tar.gz"

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

if [ -f $DEP_LIBEVENT ];then
	libevent_dir=$(tar -tf $DEP_LIBEVENT | head -1)
	tar -xf $DEP_LIBEVENT
	echo "libevent_dir=$libevent_dir"
	cd $libevent_dir
	if [ -f configure ];then
		rotate_line &
		disown $!
		./configure > $NULL
		result=$?
		result_info $result "libevent configure"  "31"
		make > $NULL
		result_info $? "libevent make" "31"
		make install > $NULL
		result_info $? "libevent make install" "31"
		kill -9 $!
	else 
		print_info "libevent cofigure no such file." "Fail"
		exit 32
	fi
else 
	print_info "install tar file no such file." "Fail"
	exit 29
fi

\cp /usr/local/lib/libevent* /usr/lib/
ldconfig

cd ..

if [ -f $MEMCACHED_INTAR ];then
	memcached_dir=$(tar -tf $MEMCACHED_INTAR | head -1)
	tar -xf $MEMCACHED_INTAR
	cd $memcached_dir
	if [ -f configure ];then
		rotate_line &
		disown $!
		./configure > $NULL
		result=$?
		result_info $result "memcached configure"  "32"
		make > $NULL
		result_info $? "memcached make" "33"
		make install > $NULL
		result_info $? "mecached make install" "34"
		kill -9 $!
	else 
		print_info "mecached cofigure no such file." "Fail"
		exit 32
	fi
else 
	print_info "install mecached  tar file no such file." "Fail"
	exit 29
fi

