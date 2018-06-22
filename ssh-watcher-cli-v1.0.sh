#!/bin/bash

# https://github.com/WestleyK/ssh-watcher
# created by Westley K
# email westley@sylabs.io
# date created: Jun 21, 2018
# date updated: Jun 21, 2018
# version-1.0



# check if the script is running
run=$( ps aux | grep ssh-watcher.sh | wc -l )
if [[ $run -ge "2" ]]; then
	echo "script already running!"
	echo "try: ps aux | grep ssh-watcher-cli-v1.0.sh"
	exit
fi

option=$1
if [[ -n $option ]]; then
	case $option in
	-h | -help)
			echo "usage: ./ssh-watcher-cli-v1.0.sh [-option]
	-h | -help | --help (display help menu)
	-c (clear terminal before running script)
	-o | -i (dont ALERT for logout)
	-R (reboot this divice when ssh login or login attempt) (comming soon)"
		exit
		;;
	*c*)
		clear
		echo "running ssh-watcher-cli-v1.0.sh"
		;;
	*o*)
		no_logout=$"true"
		echo no_input
		;;
	*)
		echo "option not found, try: ./ssh-watcher-cli-v1.0.sh -h"
		exit
		;;
	
	esac
fi
		


#option=$1
#if [[ $option = *"h"* || $option = "help" ]]; then 
#	echo "usage: ./ssh-watcher-cli-v1.0.sh [-option]
#	-h | -help | --help (display help menu)
#	-c (clear terminal before running script)
#	-o | -i (dont ALERT for logout)
#	-R (reboot this divice when ssh login or login attempt) (comming soon)"
#	exit
#elif [[ $option = *"c"* ]]; then
#	clear
#	echo "running ssh-watcher-cli-v1.0.sh"
#elif [[ $option = *"o"* || $option = *"i"* ]]; then 
#	no_logout=$"true"
#else
#	echo "usseage"
#fi


reset=0

check_login=$( cat /var/log/auth.log | grep -a New | wc -l )
check_logout=$( cat /var/log/auth.log | grep -a Removed | wc -l )
check_failed=$( cat /var/log/auth.log | grep -a authentication\ failure | wc -l )

c_login=$check_login
c_logout=$check_logout
c_failed=$check_failed

while true; do
	# kinda a silly way of doing this, but it works :)
	check_login=$( cat /var/log/auth.log | grep -a New | wc -l )
	check_logout=$( cat /var/log/auth.log | grep -a Removed | wc -l )
	check_failed=$( cat /var/log/auth.log | grep -a authentication\ failure | wc -l )
	
	if [[ $reset == "10" ]]; then
		c_login=$check_login
		c_logout=$check_logout
		c_failed=$check_failed
		reset=0
	fi

	# check the log every 5 seconds
	sleep 5s

	let "n_login = $check_login - $c_login"
	let "n_logout = $check_logout - $c_logout"
	let "n_failed = $check_failed - $c_failed"
	
	if [[ $n_login -ge "1" ]]; then
		reset=1
	fi
	if [[ $n_logout -ge "1" ]]; then
		reset=2
	fi
	if [[ $n_failed -ge "1" ]]; then
		reset=3
	fi


	if [[ $reset == "1" ]]; then
		hack_ip=$( cat /var/log/auth.log | tail | grep -a pi\ from | tail -1 | sed 's/.*from //' | cut -f1 -d" " )
		echo "ALERT: someone is ssh-ing your devive, you should do somthing! there ip address:$hack_ip"
		reset=10
	fi

	if [[ $reset == "2" && $no_logout != "true" ]]; then
		hack_ip=$( cat /var/log/auth.log | tail | grep -a pi\ from | tail -1 | sed 's/.*from //' | cut -f1 -d" " )
		echo "ALERT: someone just stoped ssh-ing you device, you must be safe now. there ip address:$hack_ip"
		reset=10
	fi

	if [[ $reset == "3" ]]; then 
		hack_ip=$( cat /var/log/auth.log | tail | grep -a pi\ from | tail -1 | sed 's/.*from //' | cut -f1 -d" " )
		echo "ALERT: Someone is trying to login to your device, there ip address:$hack_ip"
		reset=10

	fi


done
