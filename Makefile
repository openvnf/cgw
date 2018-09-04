all: create-toc

create-toc:
	markdown-toc --bullets="*" -i README.md

.PHONY: create-toc

