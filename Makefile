# spago executable
SPAGO := ./stage/toolchain/spago

# Use this as a target to track spago configuration/output changes
# (TODO: use `stage/sources.txt`?)
SPAGO_DEPS := $(SPAGO) spago.yaml spago.lock .spago/p/*/src/**/*.purs .spago/p/*/src/**/*.purs

.DEFAULT: output/PureOfScript/bundle.js
output/PureOfScript/index.js: $(SPAGO_DEPS) src/PureOfScript.purs
	$(SPAGO) build

# The bundle is more efficient for node startup times ;_;
output/PureOfScript/bundle.js: $(SPAGO_DEPS) src/PureOfScript.purs
	$(SPAGO) bundle --module PureOfScript --platform node --bundle-type module --outfile output/PureOfScript/bundle.js

output/Main/index.js: $(SPAGO_DEPS) src/Main.purs
	# $(SPAGO) build
	# We skirt around spago because it is slow to start up
	# The sources are newline-delimited globs
	set -o noglob; IFS="\n" purs compile $$(cat stage/sources.txt)
	# ugly hack, please fix
	if [ output/Main/index.js -ot spago.lock ]; then touch output/Main/index.js; fi

# `spago sources` is slow (1800ms on index.dev.js, 1200ms on bundle.js), so we cache it
stage/sources.txt: $(SPAGO_DEPS)
	$(SPAGO) sources > stage/sources.txt

# `spago.lock` depends on `spago.yaml`, reinstall if `spago.yaml` changes
spago.lock: spago.yaml
	$(SPAGO) install
	# ugly hack, please fix
	if [ spago.lock -ot spago.yaml ]; then touch spago.lock; fi
