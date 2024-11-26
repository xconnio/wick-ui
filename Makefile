install:
	flutter pub get

lint:
	dart analyze --fatal-infos

lint-fix:
	dart fix --apply

check-format:
	dart format --output=none --set-exit-if-changed --line-length 120 .

format:
	dart format --line-length 120 .

build-apk:
	flutter build apk

tests:
	flutter test

build-web:
	flutter build web --release

build-web-ci:
	flutter build web --release --base-href "/wick/"
