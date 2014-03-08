archive:
	tar cvzf config.tgz * --exclude=config.tgz
clean:
	rm -f config.tgz
