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
	poetry install

upgrade: install
	brew upgrade
	asdf update
	asdf plugin-update --all
