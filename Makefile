# Makefile for Fletch (HTTP Client)
# Supporting Dev, Staging, and Prod environments

.PHONY: help run-dev run-staging run-prod build-dev build-staging build-prod test test-dev test-staging test-prod clean

help:
	@echo "Fletch HTTP Client - Makefile"
	@echo "============================="
	@echo "Execução (flutter run):"
	@echo "  make run-dev         - Executa o app no ambiente Dev (padrão)"
	@echo "  make run-staging     - Executa o app no ambiente Staging"
	@echo "  make run-prod        - Executa o app no ambiente Prod"
	@echo ""
	@echo "Compilação (flutter build):"
	@echo "  make build-dev       - Compila a versão de release para Dev"
	@echo "  make build-staging   - Compila a versão de release para Staging"
	@echo "  make build-prod      - Compila a versão de release para Prod"
	@echo ""
	@echo "Testes unitários (flutter test):"
	@echo "  make test            - Roda os testes com o ambiente padrão (Dev)"
	@echo "  make test-dev        - Roda os testes simulando ambiente Dev"
	@echo "  make test-staging    - Roda os testes simulando ambiente Staging"
	@echo "  make test-prod       - Roda os testes simulando ambiente Prod"
	@echo ""
	@echo "Limpeza:"
	@echo "  make clean           - Limpa os arquivos de build temporários"

# --- RUN targets ---
run-dev:
	FLAVOR=dev flutter run --dart-define=FLAVOR=dev

run-staging:
	FLAVOR=staging flutter run --dart-define=FLAVOR=staging

run-prod:
	FLAVOR=prod flutter run --dart-define=FLAVOR=prod

# --- BUILD targets ---
build-dev:
	FLAVOR=dev flutter build linux --release --dart-define=FLAVOR=dev

build-staging:
	FLAVOR=staging flutter build linux --release --dart-define=FLAVOR=staging

build-prod:
	FLAVOR=prod flutter build linux --release --dart-define=FLAVOR=prod

# --- TEST targets ---
test:
	flutter test

test-dev:
	flutter test --dart-define=FLAVOR=dev

test-staging:
	flutter test --dart-define=FLAVOR=staging

test-prod:
	flutter test --dart-define=FLAVOR=prod

# --- CLEAN target ---
clean:
	flutter clean
