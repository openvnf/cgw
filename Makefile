DOCS := $(wildcard docs/*.md)

all: create-toc create-doc-tocs

create-toc:
	markdown-toc --bullets="*" -i README.md

create-doc-tocs: $(DOCS)
	$(foreach f,$^,markdown-toc --bullets="*" -i $(f);)

.PHONY: create-toc create-doc-tocs

