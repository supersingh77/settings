.PHONY: linux setup-dev audit test setup-host setup-user

linux:
	$(MAKE) setup-dev
	$(MAKE) audit

setup-dev:
	python3 -m venv .venv
	.venv/bin/pip install ruff==0.17.4

audit:
	.venv/bin/python scripts/audit.py

test:
	.venv/bin/python -m unittest discover -s device/fedora-laptop/tests -v

setup-host:
	bash device/fedora-laptop/scripts/setup-host.sh

setup-user:
	bash device/fedora-laptop/scripts/setup-user.sh
