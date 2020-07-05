help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   install     to install the mod"
	@echo "   ldoc        to generate an LDoc documentation"
	@echo "   uninstall   to uninstall the mod"
	@echo "   workshop    to prepare the Steam Workshop directory"

install:
	@:$(call check_defined, DST_MODS)
	@rsync -az \
		--exclude '.*' \
		--exclude 'CHANGELOG.md' \
		--exclude 'Makefile' \
		--exclude 'README.md' \
		--exclude 'config.ld' \
		--exclude 'description.txt*' \
		--exclude 'doc/' \
		--exclude 'luacov*' \
		--exclude 'readme/' \
		--exclude 'spec/' \
		--exclude 'workshop/' \
		. \
		"${DST_MODS}/dst-mod-keep-following/"

uninstall:
	@:$(call check_defined, DST_MODS)
	@rm -Rf "${DST_MODS}/dst-mod-keep-following/"

ldoc:
	@find ./doc/* -type f -not -name Dockerfile -not -name docker-stack.yml -not -wholename ./doc/ldoc/ldoc.css -delete
	@ldoc .

workshop:
	@rm -Rf ./workshop/
	@mkdir -p ./workshop/
	@cp -R ./modicon.* ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

.PHONY: workshop
