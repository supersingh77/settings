LAPTOP = PYTHONPATH=device/fedora-laptop python3 -m laptop
RUFF_VERSION = 0.17.4

.PHONY: linux setup-dev audit test capture drift restore shell phone

linux: setup-dev audit

setup-dev: .venv/bin/ruff

.venv/bin/ruff:
	python3 -m venv .venv
	.venv/bin/pip install ruff==$(RUFF_VERSION)

audit: .venv/bin/ruff
	.venv/bin/python scripts/audit.py

test:
	.venv/bin/python -m unittest discover -s tests -t .
	cd device/fedora-laptop && ../../.venv/bin/python -m unittest discover -s tests -t .

capture:
	$(LAPTOP) capture

drift:
	$(LAPTOP) capture --check

restore:
	$(LAPTOP) restore $(ARGS)

shell:
	$(LAPTOP) shell $(ARGS)

phone:
	$(LAPTOP) phone $(ARGS)
