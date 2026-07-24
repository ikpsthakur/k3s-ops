SHELL := /usr/bin/env bash

.PHONY: render validate install uninstall status logs port-forward-vm port-forward-alertmanager test-email

render:
	./scripts/render.sh

validate: render
	./scripts/validate.sh

install: validate
	kubectl apply -f .rendered/

uninstall:
	kubectl delete -f .rendered/ --ignore-not-found

status:
	kubectl -n "$${NAMESPACE:-monitoring}" get pods,svc,pvc

logs:
	kubectl -n "$${NAMESPACE:-monitoring}" logs deployment/vmagent --tail=100

port-forward-vm:
	kubectl -n "$${NAMESPACE:-monitoring}" port-forward service/victoria-metrics 8428:8428

port-forward-alertmanager:
	kubectl -n "$${NAMESPACE:-monitoring}" port-forward service/alertmanager 9093:9093

test-email:
	./scripts/test-alert.sh
