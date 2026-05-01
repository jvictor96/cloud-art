source ${HOME}/.cloud/cloudrc      # Defines spacing, etc

export COLUMNS=$(tput cols)
export LINES=$(tput lines)

function quit() {
	[ -e /tmp/final-buffer.txt ] && cat /tmp/final-buffer.txt || $(cat /tmp/cmd.sh)
	exit $?
}

if [[ "$SKIP" == "true" ]]; then
	quit
fi

function place_images() { # place images generates a map of places that images can be places. (/tmp/map)
	while IFS= read -r art; do #art receives dimensions line by line. dimensions contains dimentions and filename
		dim=($(echo $art))
		status=F  # each loop prints the cordinates of image placing only once
		height=0
		pos=0
		cursor=0
		starting_point=$((lastprint + 1 + SPACING))
		sizex=${dim[0]}
		sizey=${dim[1]}
		filename=${dim[2]}
		first_line=${buffer[0]}
		min_dif=0
		for line in "${buffer[@]}"; do
			cursor=$(($cursor + 1))
			line=$(echo -e "$line")
			if (( COLUMNS - ${#line} > sizex )) && (( cursor >= starting_point )); then
				height=$(($height + 1))
				if (( $min_dif < ${#line} )); then
					min_dif=${#line}
				fi
				if (( height > sizey )) && [[ "$status" == "F" ]]; then  # if success status goes to true and lastprint is marked
					status=T
					modified=1
					lastprint=$(( pos + sizey + SPACING ))
				fi
			elif [[ "$status" == "F" ]]; then  # apparently status = T locks pos and lastprint
				pos=$cursor
				min_dif=${#line}
				height=0
			fi
		done
		echo "$status $pos $sizex $sizey $min_dif $filename" >> /tmp/map  # will print event if status=F 
	done < ${HOME}/.cloud/dimensions
}

function manipulate_buffer() {
	cursor=0
	while IFS= read -r status; do  #reads from /tmp/map
		status=($(echo $status))
		posy=${status[1]}
		sizex=${status[2]}
		sizey=${status[3]}
		min_dif=${status[4]}
		filename=${status[5]}
		if [[ "${status[0]}" == "T" ]]; then
			mapfile -t art < $filename
			fuzz=$((RANDOM % (COLUMNS - min_dif - sizex - 1)))
			while (( cursor < posy )); do
				printf "%s\n" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
				cursor=$(($cursor + 1))
			done
			while (( cursor < ( posy + sizey ) )); do
				art_line="${art[$((cursor - posy))]}"
				ghost_bytes=$(( $(echo "${buffer[$cursor]}" | wc -c) - $(echo "${buffer[$cursor]}" | wc -m) ))
				exp="%-$((min_dif + fuzz + ghost_bytes))s%s\n"
				printf "$exp" "${buffer[$cursor]}" "$art_line" >> /tmp/final-buffer.txt
				cursor=$(($cursor + 1))
			done
		fi
	done < /tmp/map
}

cloud_left
if [[ $? -ne 0 ]]; then
	exit $?
fi

if [[ ! -e "${HOME}/.cloud/dimensions" ]]; then
	quit
fi

[ -e /tmp/final-buffer.txt ] && mapfile -t buffer < <(cat /tmp/final-buffer.txt) || mapfile -t buffer < <($(cat /tmp/cmd.sh))
rm -f /tmp/final-buffer.txt

art_amount=$(wc -l ${HOME}/.cloud/dimensions | cut -d" " --field 1)

buffer_sizey=${#buffer[@]}
if (( $buffer_sizey > $MAX_LINES )); then
	printf "%s\n" "${buffer[@]}"
	exit 10
fi

lastprint=0
modified=0
place_images
while (( $modified == 1 )); do # place_images manipulates lastprint and modified, while it tries fitting all the images
	modified=0
	place_images
done

if [[ -e "/tmp/map" ]]; then
	manipulate_buffer
fi

[ -e /tmp/final-buffer.txt ] && cat /tmp/final-buffer.txt || printf "%s\n" "${buffer[@]}"
rm -f /tmp/map /tmp/final-buffer.txt
