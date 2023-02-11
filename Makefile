.PHONY: \
	setup \
	install \
	upgrade

setup:
	@echo セットアップを開始します
	./setup.sh

install:
	brew bundle
	asdf install
	pip install poetry
	poetry install
	pre-commit install --install-hooks
	pre-commit run -a


upgrade: install
	brew upgrade
	asdf update
	asdf plugin-update --all
	pre-commit autoupdate
