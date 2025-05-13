#!/bin/bash

source ${HOME}/.cloud/cloudrc      # Defines padding, spacing, shuffles, etc

function place_images() {
	while IFS= read -r art; do
		dim=($(echo $art))
		sizex=${dim[0]}
		sizey=${dim[1]}
		filename=${dim[2]}
		pos=$(( lastprint + SPACING))
		lastprint=$(( lastprint + sizey + SPACING))
		echo "$status $pos $sizex $sizey $filename" >> /tmp/map 
	done < ${HOME}/.cloud/left_dimensions
}

function manipulate_buffer() {
	mapfile -t buffer < /tmp/buffer.txt
	cursor=0
	while IFS= read -r entry; do
		entry=($(echo $entry))
		posy=${entry[1]}
		sizex=${entry[2]}
		sizey=${entry[3]}
		filename=${entry[4]}
		mapfile -t art < $filename
		while (( cursor < posy )); do
			printf "%s\n" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			cursor=$(( cursor + 1 ))
		done
		while (( cursor < posy + size )); do
			if command -v zsh 2&>1 > /dev/null; then
				art_line="${art[$((cursor - posy))]}"
				dif=$((sizex - ${#art_line}))
				zsh -c 'printf "%s %'"$((dif))"'s\n" "$1" "$2"' _ "${art[$((cursor - posy))]}" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			else
				bash -c 'printf "%s %'"$((dif))"'s\n" "$1" "$2"' _ "${art[$((cursor - posy))]}" "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			fi
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

$(cat /tmp/cmd.sh) > /tmp/buffer.txt

buffer_sizex=0
while IFS= read -r line; do
	line="$(echo -e $line | expand)"
    line_sizex=$(echo $line | wc -m)
	if (( line_sizex > buffer_sizex )); then
	buffer_sizex=$line_sizex
	fi
done < ${HOME}/.cloud/left_dimensions

if (( buffer_sizex + art_sizex > COLUMNS )); then
	cat /tmp/buffer.txt
	rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt /tmp/shuffle
	exit 0
fi

dim_buffer=$(wc -l /tmp/buffer.txt | cut -d" " --field 1)

if (( $dim_buffer > $MAX_LINES )); then
	cat /tmp/buffer.txt
	rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt /tmp/shuffle
	exit 0
fi

lastprint=0
printing=true
while [[ "$printing" == "true" ]]; do
	for j in $(seq $SHUFFLES); do
		h=$(((RANDOM % art_amount) + 1))
		t=$((art_amount - h))
		tail -n $t ${HOME}/.cloud/left_dimensions > /tmp/shuffle
		head -n $h ${HOME}/.cloud/left_dimensions >> /tmp/shuffle
		mv /tmp/shuffle ${HOME}/.cloud/left_dimensions
	done
	last_lastprint=$lastprint
	place_images $(( REPETITION_RANGE * ( i - 1 ) ))
	if [[ "$last_lastprint" == "$lastprint" ]]; then
		printing=false
	fi
done

if [[ -e "/tmp/map" ]]; then
	manipulate_buffer
fi

[ -e /tmp/final-buffer.txt ] && cat /tmp/final-buffer.txt || cat /tmp/buffer.txt
rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt /tmp/shuffle
