help:
	@echo "Please use \`make <target>' where <target> is one of:\n"
	@echo "   workshop   to prepare directory for upload to Steam Workshop."

workshop:
	@rm -Rf ./workshop/
	@mkdir -p ./workshop/
	@cp -R ./modicon.* ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

.PHONY: workshop
