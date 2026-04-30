#!/bin/bash

source ${HOME}/.cloud/cloudrc      # Defines padding, spacing, etc

if [[ -z "$(ls ~/.cloud/left_art)" ]]; then
	quit
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
	mapfile -t buffer < /tmp/buffer.txt
	cursor=0
	while IFS= read -r entry; do
		entry=($(echo $entry))
		posy=${entry[0]}
		sizex=${entry[1]}
		sizey=${entry[2]}
		filename=${entry[3]}
		mapfile -t art < $filename
		while (( cursor < posy )); do
			dif=$((art_sizex + ${#buffer[$cursor]}))
			if command -v zsh 2>&1 > /dev/null; then
				zsh -c 'printf " %'"$((dif))"'s\n" "$1"' _ "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			else
				bash -c 'printf " %'"$((dif))"'s\n" "$1"' _ "${buffer[$cursor]}" >> /tmp/final-buffer.txt
			fi
			cursor=$(( cursor + 1 ))
		done
		while (( cursor < posy + sizey )); do
			art_line="${art[$((cursor - posy))]}"
			dif=$((art_sizex - ${#art_line} + ${#buffer[$cursor]}))
			if command -v zsh 2>&1 > /dev/null; then
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

buffer_sizey=$(wc -l /tmp/buffer.txt | cut -d" " --field 1)
buffer_sizex=0
while IFS= read -r line; do
	line="$(echo -e $line | expand)"
    line_sizex=$(echo $line | wc -m)
	if (( line_sizex > buffer_sizex )); then
	buffer_sizex=$line_sizex
	fi
done < /tmp/buffer.txt

if (( buffer_sizex + art_sizex > COLUMNS )); then
	cat /tmp/buffer.txt
	rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt
	exit 0
fi

if (( $buffer_sizey > $MAX_LINES )); then
	cat /tmp/buffer.txt
	rm -f /tmp/map /tmp/final-buffer.txt /tmp/buffer.txt
	exit 0
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
