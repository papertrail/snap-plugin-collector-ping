.PHONY: pkg

default:
	$(MAKE) deps
	$(MAKE) all
test:
	$(MAKE) deps
	bash -c "./scripts/test.sh $(TEST)"
deps:
	bash -c "./scripts/deps.sh"
check:
	$(MAKE) test
all:
	bash -c "./scripts/build.sh $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) code"
pkg:
	bash -c "./scripts/build.sh $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) pkg"
