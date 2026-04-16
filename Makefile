SHELL := /usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: shell chrome run-via-playwrite check-via-playwrite

shell:
	nix develop

chrome:
	jsonhub-chrome

run-via-playwrite:
	# `make run-via-playwrite foo` treats `foo` as another goal; filter it back into a script name.
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make run-via-playwrite <script-name>"; \
		exit 1; \
	fi
	@./nix/scripts/run-via-playwrite.sh $(filter-out $@,$(MAKECMDGOALS))

check-via-playwrite:
	# `make check-via-playwrite foo` treats `foo` as another goal; filter it back into a script name.
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make check-via-playwrite <script-name>"; \
		exit 1; \
	fi
	@./nix/scripts/check-via-playwrite.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
