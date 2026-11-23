SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

ifeq ($(VERILATOR_ROOT),)
  VERILATOR = verilator
else
  export VERILATOR_ROOT
  VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

$(info Using Verilator: $(realpath $(VERILATOR)))

help:
	@echo "Usage: make [target] TOP_MODULE=<module_name>"
	@echo "Targets:"
	@echo "  lint   - Run Verilator lint checks on the specified top module."
	@echo "  build  - Build the Verilator model for the specified top module."
	@echo "  run    - Run the compiled Verilator model for the specified top module."
	@echo "  clean  - Clean the output directory for the specified top module."
	@echo ""
	@echo "Available Modules (from filelists/):"
	@ls -1 filelists/*.rtl.f 2>/dev/null | sed 's|filelists/||;s|.rtl.f||' | sed 's/^/  - /'

# Fail if TOP_MODULE is not defined
check_vars:
	@if [ -z "$(TOP_MODULE)" ]; then \
		echo "ERROR: TOP_MODULE is not defined."; \
		echo "Usage: make $(MAKECMDGOALS) TOP_MODULE=<module_name>"; \
		exit 1; \
	fi

FILELIST = filelists/$(TOP_MODULE).rtl.f
RTL_PLUSARGS = filelists/$(TOP_MODULE).defines.f
VERILATOR_ARGS = filelists/$(TOP_MODULE).verilator.vlt
OUTPUT_DIR = output/$(TOP_MODULE)
LOGS_DIR = logs/$(TOP_MODULE)
export DESIGN_RTL_DIR = external/cv32e40x/rtl
# Default to one worker so shell startup output cannot corrupt Verilator's -j flag.
# Override on the command line for parallel builds, for example: make build NPROC=8.
# NPROC ?= $(nproc)
NPROC ?= 1

# --timing \
#	--debug \
# --gdbbt \

VERILATOR_FLAGS += \
	-Wall \
	-j $(NPROC) \
	--top-module $(TOP_MODULE) \
	$(VERILATOR_ARGS) \
	-f $(RTL_PLUSARGS) \
	-f $(FILELIST)

.PHONY: help check_vars lint build run clean

lint: check_vars
	@echo "LINT: $(TOP_MODULE)"

	@mkdir -p logs/$(TOP_MODULE)
	@$(VERILATOR) --lint-only $(VERILATOR_FLAGS) 2>&1 | tee $(LOGS_DIR)/lint.log

$(OUTPUT_DIR)/V$(TOP_MODULE):
	@echo "VERILATE: $(TOP_MODULE)"
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p logs/$(TOP_MODULE)
	@$(VERILATOR) --binary $(VERILATOR_FLAGS) -Mdir $(OUTPUT_DIR) 2>&1 | tee $(LOGS_DIR)/verilate.log

build: check_vars $(OUTPUT_DIR)/V$(TOP_MODULE)

run: build check_vars
	@echo "RUN: $(TOP_MODULE)"
	@mkdir -p logs/$(TOP_MODULE)
	@chmod +x $(OUTPUT_DIR)/V$(TOP_MODULE)
	@./$(OUTPUT_DIR)/V$(TOP_MODULE) 2>&1 | tee $(LOGS_DIR)/run.log

clean:
	@echo "CLEAN: $(TOP_MODULE)"
	@rm -rf $(OUTPUT_DIR) $(LOGS_DIR)
