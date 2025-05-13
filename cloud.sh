#!/bin/bash

source ${HOME}/.cloud/cloudrc      # Defines padding, spacing, shuffles, etc

if [[ "$ALIGN" == "LEFT" ]]; then
	cloud_left
	exit 0
fi

if [[ "$ALIGN" == "CORNERS" ]]; then
	cloud_corners
	exit 0
fi

function place_images() {
	while IFS= read -r art; do
		dim=($(echo $art))
		status=F
		height=0
		pos=0
		cursor=0
		starting_point=$1
		sizex=${dim[0]}
		sizey=${dim[1]}
		filename=${dim[2]}
		first_line=$(head -n 1 /tmp/buffer.txt | expand)
		min_dif=$(($COLUMNS - ${#first_line} - $PADDING - $sizex))
		while IFS= read -r line; do
			cursor=$(($cursor + 1))
			line=$(echo -e "$line" | expand)
			if (( COLUMNS - ${#line} > sizex )) && (( cursor > lastprint )) && (( cursor >= starting_point )); then
				height=$(($height + 1))
				if (( $min_dif > ($COLUMNS - ${#line} - 1 - $sizex) )); then
					min_dif=$(($COLUMNS - ${#line} - 1 - $sizex))
				fi
				if (( height > sizey )) && [[ "$status" == "F" ]]; then
					status=T
					lastprint=$(( pos + sizey + SPACING ))
				fi
			elif [[ "$status" == "F" ]]; then
				pos=$cursor
				min_dif=$(($COLUMNS - ${#line} - 1 - $sizex))
				height=0
			fi
		done < /tmp/buffer.txt
		echo "$status $pos $sizex $sizey $min_dif $filename" >> /tmp/map 
	done < ${HOME}/.cloud/dimensions
}

function manipulate_buffer() {
	while IFS= read -r status; do
		status=($(echo $status))
		posy=${status[1]}
		sizex=${status[2]}
		sizey=${status[3]}
		min_dif=${status[4]}
		filename=${status[5]}
		if [[ "${status[0]}" == "T" ]]; then
			mapfile -t art < $filename
			cursor=0
			if [[ "$ALIGN" == "RANDOM" ]]; then
				fuzz=$((3*(RANDOM % min_dif)))
				if (( "$fuzz" > "$min_dif" )); then
					fuzz=$((RANDOM % min_dif))
				fi
			fi
			cursor=0
			while IFS= read -r line; do
				if (( "$cursor" >= "$posy" )) && (( cursor < $(( posy + sizey)) )); then
					line="$(echo -e $line | expand)"
					art_line="${art[$((cursor - posy))]}"
					dif=$(($COLUMNS - ${#line} - PADDING - sizex + ${#art_line}))
					if command -v zsh 2>&1 > /dev/null; then
						zsh -c 'printf "%s %'"$((dif - fuzz))"'s\n" "$1" "$2"' _ "$line" "${art[$((cursor - posy))]}" >> /tmp/final-buffer.txt
					else
						bash -c 'printf "%s %'"$((dif - fuzz))"'s\n" "$1" "$2"' _ "$line" "${art[$((cursor - posy))]}" >> /tmp/final-buffer.txt
					fi
				else
					printf "%s\n" "$line" >> /tmp/final-buffer.txt
				fi
				cursor=$(($cursor + 1))
			done < /tmp/buffer.txt
			mv /tmp/final-buffer.txt /tmp/buffer.txt 
		fi
	done < /tmp/map
}

art_amount=$(wc -l ${HOME}/.cloud/dimensions | cut -d" " --field 1)

$(cat /tmp/cmd.sh) > /tmp/buffer.txt

dim_buffer=$(wc -l /tmp/buffer.txt | cut -d" " --field 1)

if (( $dim_buffer > $MAX_LINES )); then
	cat /tmp/buffer.txt
	rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt /tmp/shuffle
	exit 0
fi

lastprint=0
for i in $(seq $((dim_buffer / REPETITION_RANGE + 1))); do
	for j in $(seq $SHUFFLES); do
		h=$(((RANDOM % art_amount) + 1))
		t=$((art_amount - h))
		tail -n $t ${HOME}/.cloud/dimensions > /tmp/shuffle
		head -n $h ${HOME}/.cloud/dimensions >> /tmp/shuffle
		mv /tmp/shuffle ${HOME}/.cloud/dimensions
	done
	place_images $(( REPETITION_RANGE * ( i - 1 ) ))
done

if [[ -e "/tmp/map" ]]; then
	manipulate_buffer
fi

[ -e /tmp/final-buffer.txt ] && cat /tmp/final-buffer.txt || cat /tmp/buffer.txt
rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt /tmp/shuffle
