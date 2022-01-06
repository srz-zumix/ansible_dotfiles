PYTHON:=python

#
# help
#
help: ## show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sed -e 's/^GNUmakefile://' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

pyvenv.cfg:
	${PYTHON} -m venv .

bin/ansible: pyvenv.cfg requirements.txt
	./bin/pip3 install -r requirements.txt
bin/ansible-lint: bin/ansible
bin/ansible-vault: bin/ansible
bin/ansible-playbook: bin/ansible

reinstall_ansible:
	./bin/pip3 uninstall -y ansible
	./bin/pip3 uninstall -y ansible-base
	./bin/pip3 install -r requirements.txt

init: pyvenv.cfg bin/ansible bundle_install ## init working directory
	./bin/ansible-playbook --version

define select_tags
	$(eval TAGS=$(shell cat site.yml | yq -r -e ".[].roles | .[].tags | .[]" -  | sort | uniq | peco))
	$(eval PLAYBOOK_TAG=-t ${TAGS})
endef

define playbook
	./bin/ansible-playbook -i hosts site.yml ${OPT} ${PLAYBOOK_OPTS} $1
endef

.PHONY: playbook-tag
playbook-tag: bin/ansible-playbook check-private-key ## playbook (interactive select tag)
	$(call select_tags)
	@echo recommend: "make playbook OPT=\"${PLAYBOOK_TAG}\""
	$(call playbook,${PLAYBOOK_TAG})
	@echo recommend: "make playbook OPT=\"${PLAYBOOK_TAG}\""

.PHONY: list-tasks
list-tasks: ## list tasks
	$(call select_tags)
	$(call playbook,${PLAYBOOK_TAG} --list-tasks)

playbook: bin/ansible-playbook check-private-key ## playbook
	$(call playbook, )


#
# kitchen
#

TEST_TARGET:=test
INSTANCE_NAME:=${TEST_TARGET}-ubuntu-focal64

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

bundle_reinstall:
	bundle install --path vendor/bundle

bundle_install: Gemfile.lock

kitchen-list: bundle_install ## kitchen list
	bundle exec kitchen list

kitchen-create: bundle_install ## kitchen create
	bundle exec kitchen create ${INSTANCE_NAME}

kitchen-converge: bundle_install ## kitchen converge
	bundle exec kitchen converge ${INSTANCE_NAME}

kitchen-verify: bundle_install ## kitchen verify
	bundle exec kitchen verify ${INSTANCE_NAME}

kitchen-login: bundle_install ## kitchen login
	bundle exec kitchen login ${INSTANCE_NAME}

kitchen-destroy: bundle_install ## kitchen destroy
	bundle exec kitchen destroy ${INSTANCE_NAME}

kitchen-exec: bundle_install ## kitchen exec CMD="cmd"
	bundle exec kitchen exec ${INSTANCE_NAME} -c "${CMD}"

kitchen-test-target-list: ## list TEST_TARGET
	@bundle exec kitchen list -b | sed -e 's/-ubuntu-.*//g' | uniq

define kitchen_taget
	$(eval TEST_TARGET=$(shell make -C . kitchen-test-target-list | peco))
endef

define kitchen_command
	$(eval KITCHEN_COMMAND=$(shell echo "converge\nlogin\nrun-agent\ntail-unityinstall\ncreate\ndestroy" | peco))
endef

kitchen-peco: ## interactive kitchen command
	$(call kitchen_taget)
	$(call kitchen_command)
	@echo recommend: "make kitchen-${KITCHEN_COMMAND} TEST_TARGET=${TEST_TARGET}"
	make -C . kitchen-${KITCHEN_COMMAND} TEST_TARGET=${TEST_TARGET}
	@echo recommend: "make kitchen-${KITCHEN_COMMAND} TEST_TARGET=${TEST_TARGET}"

#
# Lint

.PHONY: lint
lint: bin/ansible-lint
	./bin/ansible-lint roles/*
