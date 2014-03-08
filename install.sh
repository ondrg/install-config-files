#!/bin/sh
{
	CONFIG_ARCHIVE_URL='http://config.ondra.biz/config.tgz'
	CONFIG_ARCHIVE_FILE='config.tgz'

	INI_FILE='config.ini'

	if [ "$1" = '-l' ] || [ "$1" = '--local' ]; then
		# installing from local directory
		LOCAL_INSTALATION='yes'
		TMP_DIR='.'
		if [ ! -f "$INI_FILE" ]; then
			echo "ERROR! Can't find '$INI_FILE' in current directory." >&2
			exit 1
		fi
	else
		# download and extract files
		LOCAL_INSTALATION='no'
		TMP_DIR=$(mktemp -d)
		wget -q -O "$TMP_DIR/$CONFIG_ARCHIVE_FILE" "$CONFIG_ARCHIVE_URL"
		if [ $? -ne 0 ]; then
			echo "ERROR! Can't download config files. Check URL in '$0' file." >&2
			exit 1
		fi
		tar xzf "$TMP_DIR/$CONFIG_ARCHIVE_FILE" -C "$TMP_DIR"
	fi

	# parse ini file
	# source: http://mark.aufflick.com/blog/2007/11/08/parsing-ini-files-with-sed
	PARSED_INI=`sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
		-e 's/;.*$//' \
		-e 's/[[:space:]]*$//' \
		-e 's/^[[:space:]]*//' \
		-e "s/^\(.*\)=\([^\"']*\)$/\1=\2/" \
		< $TMP_DIR/$INI_FILE`

	# install scripts
	for section in $(echo "$PARSED_INI" | grep '^\[' | sed -e 's/^\[\(.*\)\]/\1/'); do
		echo "Installing '$section' configs..."
		for config in $(echo "$PARSED_INI" | sed -n -e "/^\[$section\]/,/^\s*\[/{/^[^;].*\=.*/p;}"); do
			src_file=`echo "$config" | cut -d'=' -f1`
			eval dst_file=`echo "$config" | cut -d'=' -f2`
			if [ -f "$dst_file" ]; then
				backup_file=$(date "+$dst_file.%Y-%m-%d_%H-%M-%S")
				echo "  moving old '$dst_file' file to '$backup_file'"
				mv "$dst_file" "$backup_file"
			fi
			echo "  copy '$TMP_DIR/$section/$src_file' into '$dst_file'"
			cp "$TMP_DIR/$section/$src_file" "$dst_file"
		done
	done

	# cleanup
	if [ "$LOCAL_INSTALATION" = 'no' ]; then
		rm -rf "$TMP_DIR"
	fi

	echo "Done."
}
