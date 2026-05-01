#!/bin/bash

source ${HOME}/.cloud/cloudrc      # Defines spacing, etc

if [[ ! -e "${HOME}/.cloud/left_dimensions" ]]; then
	exit 0
fi

function place_images() {
	while IFS= read -r art; do
		if (( lastprint + SPACING < buffer_sizey)); then
			dim=($(echo $art))
			sizex=${dim[0]}
			sizey=${dim[1]}
			filename=${dim[2]}
			pos=$(( lastprint + SPACING))
			lastprint=$(( pos + sizey))
			modified=1
			echo "$pos $sizex $sizey $filename" >> /tmp/map
		fi
	done < ${HOME}/.cloud/left_dimensions
}

function manipulate_buffer() {
	cursor=0
	while IFS= read -r entry; do
		entry=($(echo $entry))
		posy=${entry[0]}
		sizey=${entry[2]}
		filename=${entry[3]}
		mapfile -t art < $filename
		while (( cursor < posy )); do
			printf "%-$((art_sizex + ghost_bytes))s %s $s\n" "" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			cursor=$(( cursor + 1 ))
		done
		while (( cursor < posy + sizey )); do
			if (( cursor >= buffer_sizey )); then
				break
			fi
			art_line="${art[$((cursor - posy))]}"
			ghost_bytes=$(( $(echo "$art_line" | wc -c) - $(echo "$art_line" | wc -m) ))
			printf "%-$((art_sizex + ghost_bytes))s %s $s\n" "$art_line" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			cursor=$(( cursor + 1 ))
		done
	done < /tmp/map
}

art_amount=$(wc -l ${HOME}/.cloud/left_dimensions | cut -d" " --field 1)
art_sizex=0
while IFS= read -r line; do
	dim=($(echo $line))
	if (( ${dim[0]} > art_sizex )); then
	art_sizex=${dim[0]}
	fi
done < ${HOME}/.cloud/left_dimensions

mapfile -t buffer < <($(cat /tmp/cmd.sh))

buffer_sizey=${#buffer[@]}
buffer_sizex=0
for line in "${buffer[@]}"; do
	line="$(echo -e $line | expand)"
    line_sizex=$(echo $line | wc -m)
	if (( line_sizex > buffer_sizex )); then
	buffer_sizex=$line_sizex
	fi
done

if (( buffer_sizex + art_sizex > COLUMNS )); then
	printf "%s\n" "${buffer[@]}"
	exit 10
fi


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

rm -f /tmp/map

