GIT_LATEST_TAG = $$(git describe --abbrev=0)
GIT_SUBMODULE_COMMIT = $$(git submodule foreach git rev-parse --short HEAD | tail -1)
MODINFO_VERSION = $$(grep '^version.*=' < modinfo.lua | awk -F'= ' '{ print $$2 }' | tr -d '"')
PRETTIER_GLOBAL_DIR = /usr/local/share/.config/yarn/global

# Source: https://stackoverflow.com/a/10858332
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))

help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   dev                   to run reinstall + ldoc + lint + testclean + test"
	@echo "   gitrelease            to commit modinfo.lua and CHANGELOG.md + add a new tag"
	@echo "   install               to install the mod"
	@echo "   ldoc                  to generate an LDoc documentation"
	@echo "   ldocclean             to clean up generated LDoc documentation"
	@echo "   lint                  to run code linting (Luacheck + Prettier)"
	@echo "   luacheck              to run Luacheck"
	@echo "   luacheckglobals       to print Luacheck globals (mutating/setting)"
	@echo "   luacheckreadglobals   to print Luacheck read_globals (reading)"
	@echo "   modicon               to pack modicon"
	@echo "   prettier              to run Prettier"
	@echo "   reinstall             to uninstall and then install the mod"
	@echo "   release               to update version"
	@echo "   test                  to run Busted tests"
	@echo "   testclean             to clean up after tests"
	@echo "   testcoverage          to print the tests coverage report"
	@echo "   testlist              to list all existing tests"
	@echo "   uninstall             to uninstall the mod"
	@echo "   updatesdk             to update SDK to the latest version"
	@echo "   workshop              to prepare the Steam Workshop directory + archive"
	@echo "   workshopclean         to clean up Steam Workshop directory + archive"

dev: reinstall ldoc lint testclean test

gitrelease:
	@echo "Latest Git tag: ${GIT_LATEST_TAG}"
	@echo "Modinfo version: ${MODINFO_VERSION}\n"

	@printf '1/5: Resetting (git reset)...'
	@git reset > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '2/5: Adding and commiting modinfo.lua...'
	@git add modinfo.lua > /dev/null 2>&1
	@git commit -m 'Update modinfo: version and description' > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '3/5: Adding and commiting CHANGELOG.md...'
	@git add CHANGELOG.md > /dev/null 2>&1
	@git commit -m "Update CHANGELOG.md: release ${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf "4/5: Creating a signed tag (v${MODINFO_VERSION})..."
	@git tag -s "v${MODINFO_VERSION}" -m "Release v${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@echo "5/5: Verifying tag (v${MODINFO_VERSION})...\n"
	@git verify-tag "v${MODINFO_VERSION}"

install:
	@:$(call check_defined, DST_MODS)
	@rsync -az \
		--exclude '.*' \
		--exclude 'CHANGELOG.md' \
		--exclude 'CONTRIBUTING.md' \
		--exclude 'Makefile' \
		--exclude 'README.md' \
		--exclude 'busted.out' \
		--exclude 'config.ld' \
		--exclude 'description.txt*' \
		--exclude 'docs/' \
		--exclude 'lcov.info' \
		--exclude 'luacov*' \
		--exclude 'modicon.png' \
		--exclude 'preview.*' \
		--exclude 'readme/' \
		--exclude 'spec/' \
		--exclude 'workshop*' \
		. \
		"${DST_MODS}/mod-keep-following/"

ldoc: ldocclean
	@ldoc .

ldocclean:
	@find ./docs/ -type f \( \
		-not -wholename './docs/ldoc/ldoc.css' \
		-not -wholename './docs/.dockerignore' \
		-not -wholename './docs/docker-stack.yml' \
		-not -wholename './docs/Dockerfile' \
	\) \
	-delete
	@rm -rf ./docs/classes/

lint: luacheck prettier

luacheck:
	@luacheck . --exclude-files="here/"

luacheckglobals:
	@luacheck . --formatter=plain | grep 'non-standard' | awk '{ print $$6 }' | sed -e "s/^'//" -e "s/'$$//" | sort -u

luacheckreadglobals:
	@luacheck . --formatter=plain | grep "undefined variable" | awk '{ print $$5 }' | sed -e "s/^'//" -e "s/'$$//" | sort -u

modicon:
	@:$(call check_defined, KTOOLS_KTECH)
	@${KTOOLS_KTECH} ./modicon.png . --atlas ./modicon.xml --square
	@prettier --plugin "${PRETTIER_GLOBAL_DIR}/node_modules/@prettier/plugin-xml/src/plugin.js" --xml-whitespace-sensitivity='ignore' --write './modicon.xml'

prettier:
	@prettier --plugin "${PRETTIER_GLOBAL_DIR}/node_modules/@prettier/plugin-xml/src/plugin.js" --list-different './**/*.md' './**/*.xml' './**/*.yml'

reinstall: uninstall install

release:
	@:$(call check_defined, MOD_VERSION)
	@echo "Version: ${MOD_VERSION}\n"

	@printf '1/2: Updating modinfo version...'
	@sed -i "s/^version.*$$/version = \"${MOD_VERSION}\"/g" ./modinfo.lua && echo ' Done' || echo ' Error'
	@printf '2/2: Syncing LDoc release code occurrences...'
	@find . -type f -regex '.*\.lua' -exec sed -i "s/@release.*$$/@release ${MOD_VERSION}/g" {} \; && echo ' Done' || echo ' Error'

test:
	@busted .; luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testclean:
	@find . \( -name 'busted.out' -o -name 'core' -o -name 'lcov.info' -o -name 'luacov*' \) -type f -delete

testcoverage:
	@luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testlist:
	@busted --list . | awk '{$$1=""}1' | awk '{gsub(/^[ \t]+|[ \t]+$$/,"");print}'

uninstall:
	@:$(call check_defined, DST_MODS)
	@rm -rf "${DST_MODS}/mod-keep-following/"

updatesdk:
	@rm -rf scripts/devtools/sdk/*
	@git submodule foreach git reset --hard origin/main
	@git submodule foreach git pull --ff-only origin main
	@git add scripts/keepfollowing/sdk
	@git commit -m "Update SDK: ${GIT_SUBMODULE_COMMIT}"

workshop:
	@rm -rf ./workshop*
	@mkdir -p ./workshop/
	@cp -r ./LICENSE ./workshop/
	@cp -r ./modicon.tex ./workshop/
	@cp -r ./modicon.xml ./workshop/
	@cp -r ./modinfo.lua ./workshop/
	@cp -r ./modmain.lua ./workshop/
	@cp -r ./scripts/ ./workshop/
	@rm -rf ./workshop/scripts/keepfollowing/sdk/*.md
	@rm -rf ./workshop/scripts/keepfollowing/sdk/.[!.]*
	@rm -rf ./workshop/scripts/keepfollowing/sdk/config.ld
	@rm -rf ./workshop/scripts/keepfollowing/sdk/Makefile
	@rm -rf ./workshop/scripts/keepfollowing/sdk/readme
	@rm -rf ./workshop/scripts/keepfollowing/sdk/spec
	@cp -r ./workshop/ ./workshop-1896055525/
	@zip -r ./steam-workshop.zip ./workshop-1896055525/
	@rm -rf ./workshop-1896055525/

workshopclean:
	@rm -rf ./workshop* ./steam-workshop.zip

.PHONY: workshop
