#!/bin/bash

cat masscan.txt | grep -vE "^#" | tr ' ' ',' > .temp

date=$(date)
lines=$(cat .temp | wc -l)
threads=4

trap ctrl_c INT
function ctrl_c () {
	echo "Exiting.."
	echo "</table>" >> index.html
	echo "</html>" >> index.html
	rm xa*
	rm .count
	rm .temp
	killall mainFunctionThread.sh &>/dev/null
	killall main.sh &>/dev/null
	exit 1
}

function mainFunctionThread () {
	for line in $(cat $1); do
		ipAddress=$(echo $line | awk -F ',' '{print $4}')
		portAddress=$(echo $line | awk -F ',' '{print $3}')
		if [[ $portAddress == "80" ]]; then
			requestContent=$(timeout 2 curl -s -X GET -L http://$ipAddress)
			urlPath="http://$ipAddress"
		elif [[ $portAddress == "443" ]]; then
			requestContent=$(timeout 2 curl -k -s -X GET -L https://$ipAddress)
			urlPath="https://$ipAddress"
		else
			continue
		fi
		# echo "$ipAddress $portAddress"
		# echo $requestContent | grep -oP "<title>.*?</title>"
		if [[ $(echo $requestContent) != "" ]]; then
			if [[ $(echo $requestContent | xargs -0 | grep -oP "<title>.*?</title>") != "" ]];then
				echo "<tr>" >> index.html
				echo $requestContent | grep -oP "<title>.*?</title>" | sed -e 's/<title[^>]*>/<td>/g' -e 's/<\/title>/<\/td>/g' >> index.html
				echo "<td> <a href='$urlPath' style='text-decoration:none; color: white;'> $ipAddress $portAddress </a> </td>" >> index.html
				echo "</tr>" >> index.html
			fi
		fi
		echo "-" >> .count
	done
}

function setupFilesChunksAndThreads () {
	echo "<html style='background-color: black; color: white; font-family: Arial'>" >> index.html
	echo "<table>" >> index.html

	numOfChunks=$(( $lines / $threads )) 
	split -l $numOfChunks .temp
	sleep 0.5
	if $(ls ./x* &>/dev/null) ;then
		for file in $(ls x*); do
			mainFunctionThread $file &
		done
	fi

	while true; do
		clear
		echo "Scan started at $date"
		echo "Results will be saved at index.html"
		echo
		echo "Scanning ($(cat .count | wc -l)/$lines), press ctrl-c to stop..."
		sleep 1
	done 
}

setupFilesChunksAndThreads
echo "</table>" >> index.html
echo "</html>" >> index.html

rm xa*
rm .count
rm .temp
