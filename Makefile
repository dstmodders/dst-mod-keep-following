help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   install        to install the mod"
	@echo "   ldoc           to generate an LDoc documentation"
	@echo "   lint           to run code linting"
	@echo "   modicon        to pack modicon"
	@echo "   test           to run Busted tests"
	@echo "   testcoverage   to print the tests coverage report"
	@echo "   testlist       to list all existing tests"
	@echo "   uninstall      to uninstall the mod"
	@echo "   workshop       to prepare the Steam Workshop directory"

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

ldoc:
	@find ./doc/* -type f -not -name Dockerfile -not -name docker-stack.yml -not -wholename ./doc/ldoc/ldoc.css -delete
	@ldoc .

lint:
	@EXIT=0; \
		printf "Luacheck:\n\n"; luacheck . --exclude-files="here/" || EXIT=$$?; \
		printf "\nPrettier (Markdown):\n\n"; prettier --check ./**/*.md || EXIT=$$?; \
		printf "\nPrettier (XML):\n\n"; prettier --check ./**/*.xml || EXIT=$$?; \
		printf "\nPrettier (YAML):\n\n"; prettier --check ./**/*.yml || EXIT=$$?; \
		exit $${EXIT}

modicon:
	@:$(call check_defined, DS_KTOOLS_KTECH)
	@${DS_KTOOLS_KTECH} ./modicon.png . --atlas ./modicon.xml --square

test:
	@busted . && luacov-console . && luacov-console -s

testcoverage:
	@luacov-console . && luacov-console -s

testlist:
	@busted --list . | awk '{$$1=""}1' | awk '{ gsub(/^[ \t]+|[ \t]+$$/, ""); print }'

uninstall:
	@:$(call check_defined, DST_MODS)
	@rm -Rf "${DST_MODS}/dst-mod-keep-following/"

workshop:
	@rm -Rf ./workshop/
	@mkdir -p ./workshop/
	@cp -R ./modicon.* ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

.PHONY: workshop
