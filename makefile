install:
	@echo -e 'Installing redi...'
	@install -d $(DESTDIR)/usr/share/redi/
	@install -d $(DESTDIR)/usr/bin
	@install -v -m 755 redi $(DESTDIR)/usr/bin/
	@echo -e '\e[0;32mDone!\e[0m'
	
uninstall:
	@echo "Unistalling..."
	@rm -rf $(DESTDIR)/usr/share/redi
	@rm -rf $(DESTDIR)/usr/bin/redi
	@echo "Done!"
