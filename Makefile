BINDIR = /usr/local/bin
CLOUDDIR = $(HOME)/.cloud

install:
	@echo "Installing Cloud locally..."
	mkdir -p $(BINDIR) $(CLOUDDIR)/art $(CLOUDDIR)/left_art
	cp cloudrc $(CLOUDDIR)/cloudrc
	install -m 755 cloud.sh $(CLOUDDIR)/cloud
	install -m 755 cloud_left.sh $(CLOUDDIR)/cloud_left
	install -m 755 cloudcfg.sh $(CLOUDDIR)/cloudcfg
	sudo ln -sf $(CLOUDDIR)/cloud $(BINDIR)/cloud
	sudo ln -sf $(CLOUDDIR)/cloud_left $(BINDIR)/cloud_left
	sudo ln -sf $(CLOUDDIR)/cloudcfg $(BINDIR)/cloudcfg

update:
	install -m 755 cloud.sh $(CLOUDDIR)/cloud
	install -m 755 cloud_left.sh $(CLOUDDIR)/cloud_left
	install -m 755 cloudcfg.sh $(CLOUDDIR)/cloudcfg

uninstall:
	sudo rm -f $(BINDIR)/cloud
	sudo rm -f $(BINDIR)/cloudcfg
	sudo rm -rf $(CLOUDDIR)