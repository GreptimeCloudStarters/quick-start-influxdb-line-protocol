#!/bin/bash

generate_data()
{
	unameOut="$(uname -s)"
	case "${unameOut}" in
		Linux*)
			user_cpu_util=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
			sys_cpu_util=$(top -bn1 | grep "Cpu(s)" | awk '{print $6}')
			idle_cpu_util=$(top -bn1 | grep "Cpu(s)" | awk -F "," '{print $4}' | awk -F " " '{print $1}')
			mem_util=$(free | grep Mem | awk '{print $3}')
			;;
		Darwin*)
			user_cpu_util=$(top -l 1 | awk '/^CPU usage: / { print substr($3, 1, length($3)-1) }')
			sys_cpu_util=$(top -l 1 | awk '/^CPU usage: / { print substr($5, 1, length($5)-1) }')
			idle_cpu_util=$(top -l 1 | awk '/^CPU usage: / { print substr($7, 1, length($7)-1) }')
			mem_util=$(top -l 1 | awk '/^PhysMem:/ { print substr($6, 1, length($6)-1) }')
			;;
		*)
			user_cpu_util=$(shuf -i 10-15 -n 1)
			sys_cpu_util=$(shuf -i 5-10 -n 1)
			idle_cpu_util=$(shuf -i 70-80 -n 1)
			mem_util=$(shuf -i 50-60 -n 1)
	esac
	now=$(($(date +%s)*1000000000))
	cat <<EOF
monitor,host=$unameOut user_cpu=$user_cpu_util,sys_cpu=$sys_cpu_util,idle_cpu=$idle_cpu_util,memory=$mem_util $now
EOF
}

while getopts e:h:d:u:p:P: flag
do
	case "${flag}" in
		e) endpoint=${OPTARG};;
		h) host=${OPTARG};;
		d) database=${OPTARG};;
		u) username=${OPTARG};;
		p) password=${OPTARG};;
		P) port=${OPTARG};;
	esac
done

if [ -z "$database" ]; then
	database="public"
fi

if [ -n "$endpoint" ]; then
	url="$endpoint?db=$database"
else
	if [ -z "$host" ]; then
		host="localhost"
	fi

	if [ -n "$port" ]; then
		url="https://$host:$port/v1/influxdb/write?db=$database"
	else
		url="https://$host/v1/influxdb/write?db=$database"
	fi
fi

if [ -n "$username" ]; then
  url="$url&u=$username"
fi

if [ -n "$password" ]; then
  url="$url&p=$password"
fi

echo Sending metrics to Greptime...
while true
do
	sleep 5
	curl -i -XPOST "$url" --data-binary "$(generate_data)"
done
