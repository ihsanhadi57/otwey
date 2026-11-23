# Perintah singkat OTWEY. Jalankan `make` untuk daftar perintah.
# Butuh file .env (salin dari .env.example).
ENV = --dart-define-from-file=.env

# make dari MinGW/MSYS di Windows menjalankan resep lewat sh, yang tidak bisa
# membuka flutter.bat atau npx.cmd. Lewatkan lewat cmd supaya jalan dari
# Command Prompt, PowerShell, maupun Git Bash.
ifeq ($(OS),Windows_NT)
  RUN := cmd //c
else
  RUN :=
endif
FLUTTER := $(RUN) flutter
DART := $(RUN) dart
NPX := $(RUN) npx

.DEFAULT_GOAL := help
.PHONY: help get run run-offline analyze test check apk clean db-push db-seed transit

help:
	@echo "make get          flutter pub get"
	@echo "make run          jalankan app dengan .env (Supabase)"
	@echo "make run-offline  jalankan app tanpa Supabase (data CSV)"
	@echo "make analyze      flutter analyze"
	@echo "make test         flutter test"
	@echo "make check        analyze + test"
	@echo "make apk          build APK release dengan .env"
	@echo "make clean        flutter clean lalu pub get"
	@echo "make db-push      kirim migrasi ke Supabase (remote)"
	@echo "make db-seed      kirim migrasi dan seed ke Supabase (remote)"
	@echo "make transit      hitung ulang rute transum offline Jakarta"

get:
	$(FLUTTER) pub get

run:
	$(FLUTTER) run $(ENV)

run-offline:
	$(FLUTTER) run

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

check: analyze test

apk:
	$(FLUTTER) build apk --release $(ENV)

clean:
	$(FLUTTER) clean
	$(FLUTTER) pub get

db-push:
	$(NPX) supabase@latest db push --remote

db-seed:
	$(NPX) supabase@latest db push --remote --include-seed

transit:
	$(DART) run tool/city_transit.dart --city=Jakarta
