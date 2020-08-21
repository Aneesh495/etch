# Etch EDA: Unified Makefile Automation

.PHONY: all test test-verbose verify bench build demo clean native

all: native verify test

native:
	@mkdir -p build
	@clang -std=c11 -O3 -Wall -Wextra -shared -fPIC src/native/fast_grid.c -o build/libfastgrid.dylib 2>/dev/null || true

test:
	@./node_modules/.bin/coffee tests/runner.coffee

verify:
	@python3 verify_no_em_dashes.py

bench:
	@./node_modules/.bin/coffee scripts/benchmark.coffee

demo:
	@./bin/etch demo

build:
	@mkdir -p dist
	@./node_modules/.bin/coffee -c -o dist src

clean:
	@rm -rf build dist fab_output test_output
