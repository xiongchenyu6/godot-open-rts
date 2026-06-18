all: lint format-check shaders-format-check
version = "0.9.0"

format-check:
	find source/ -name '*.gd' | xargs gdformat --check

shaders-format-check:
	find source/ -name '*.gdshader' | xargs clang-format --style=file --dry-run -Werror

lint:
	find source/ -name '*.gd' | xargs gdlint

cc:
	find source/ -name '*.gd' | xargs gdradon cc

manual-tests:
	bash tools/run_manual_tests.sh

release-smoke:
	bash tools/run_release_smoke.sh

final-check: manual-tests release-smoke

todo:
	ack ' todo' -i source/

release-linux:
	godot4 --export-release "Linux/X11" "build/Open_RTS_$(version)_linux64.bin"

release-macos:
	godot4 --export-release "macOS" "build/Open_RTS_$(version)_osx64.zip"

release-windows:
	godot4 --export-release "Windows Desktop" "build/Open_RTS_$(version)_windows64.exe"

release-web:
	mkdir -p docs
	rm -rf .godot/exported
	bash tools/export_web_clean.sh

publish-web: release-web
	touch docs/.nojekyll
	bash tools/check_web_export.sh

publish-web-verified: release-smoke publish-web

publish-web-final: final-check publish-web

release: release-linux release-macos release-windows
