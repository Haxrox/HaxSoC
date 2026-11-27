SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

export DESIGN_RTL_DIR = external/cv32e40x/rtl

ifeq ($(VERILATOR_ROOT),)
  VERILATOR = verilator
else
  export VERILATOR_ROOT
  VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

# TTY-safe ANSI colors (override with COLOR=always|never or NO_COLOR=1)
# Note: $(shell ...) runs with stdout piped to Make, so check Make's stdout (/proc/$PPID/fd/1) or stderr.
COLOR ?= auto
ifeq ($(COLOR),always)
  USE_COLOR := 1
else ifeq ($(COLOR),never)
  USE_COLOR := 0
else ifneq ($(NO_COLOR),)
  USE_COLOR := 0
else
  USE_COLOR := $(shell if [ -e /proc/$$PPID/fd/1 ]; then [ -t 0 ] </proc/$$PPID/fd/1; else [ -t 2 ]; fi 2>/dev/null && echo 1 || echo 0)
endif

ifeq ($(USE_COLOR),1)
  ESC      := $(shell printf '\033')
  C_RESET  := $(ESC)[0m
  C_BOLD   := $(ESC)[1m
  C_RED    := $(ESC)[1;31m
  C_GREEN  := $(ESC)[1;32m
  C_YELLOW := $(ESC)[1;33m
  C_ORANGE := $(ESC)[1;38;5;208m
  C_BLUE   := $(ESC)[1;34m
  C_CYAN   := $(ESC)[1;36m
  export GCC_COLORS := error=01;31:warning=01;33:note=01;36:locus=01:quote=01
  COLORIZE_LOG = | awk '{ \
    if (/^ccache /) sub(/^/, "$(TAG_CCACHE) "); \
    gsub(/(UVM_FATAL|UVM_ERROR|%Error(-[A-Z0-9_]+)?)/, "$(C_RED)&$(C_RESET)"); \
    gsub(/(UVM_WARNING|%Warning(-[A-Z0-9_]+)?)/, "$(C_YELLOW)&$(C_RESET)"); \
    gsub(/UVM_INFO/, "$(C_GREEN)&$(C_RESET)"); \
    print $$0; \
    fflush(); \
  }'
else
  C_RESET  :=
  C_BOLD   :=
  C_RED    :=
  C_GREEN  :=
  C_YELLOW :=
  C_ORANGE :=
  C_BLUE   :=
  C_CYAN   :=
  COLORIZE_LOG =
endif

_SP1 := $(subst x, ,x)
_SP2 := $(subst x, ,xx)
_SP3 := $(subst x, ,xxx)
TAG_INFO   := $(C_BLUE)[INFO$(_SP3)]$(C_RESET)
TAG_OK     := $(C_GREEN)[SUCCESS]$(C_RESET)
TAG_WARN   := $(C_YELLOW)[WARN$(_SP3)]$(C_RESET)
TAG_ERROR  := $(C_RED)[ERROR$(_SP2)]$(C_RESET)
TAG_CCACHE := $(C_ORANGE)[CCACHE$(_SP1)]$(C_RESET)

echo_info  := echo "$(TAG_INFO)"
echo_ok    := echo "$(TAG_OK)"
echo_warn  := echo "$(TAG_WARN)"
echo_error := echo "$(TAG_ERROR)"

VERILATOR_BIN := $(realpath $(shell command -v $(VERILATOR) 2>/dev/null))
ifeq ($(MAKELEVEL),0)
  $(info $(TAG_INFO) Using Verilator: $(or $(VERILATOR_BIN),$(VERILATOR) (not found)))
  $(info $(TAG_INFO) Version: $(shell $(VERILATOR) --version))
endif

help:
	@echo "$(C_BOLD)Usage:$(C_RESET) make [target] TOP_MODULE=<module_name> [TYPE={RTL,TB,UVM}] [TEST=<uvm_test>] [DUMP={0,1}]"
	@echo "$(C_BOLD)Targets:$(C_RESET)"
	@echo "  $(C_CYAN)lint$(C_RESET)   - Elaborate and run Verilator lint checks."
	@echo "  $(C_CYAN)build$(C_RESET)  - Elaborate RTL (TYPE=RTL) or build simulation binary (TYPE=TB|UVM)."
	@echo "  $(C_CYAN)run$(C_RESET)    - Build with TYPE={TB,UVM} and run the simulation binary."
	@echo "  $(C_CYAN)clean$(C_RESET)  - Clean the output and log directories for the target."
	@echo ""
	@echo "$(C_BOLD)Options:$(C_RESET)"
	@echo "  TEST=<name>       - UVM test name passed as +UVM_TESTNAME=<name> (TYPE=UVM)."
	@echo "  DUMP={0,1}        - Enable VCD waveform dump via --trace and +DUMP (default: 1)."
	@echo "  PLUSARGS=\"...\"    - Extra runtime plusargs passed to the simulation binary."
	@echo ""
	@echo "$(C_BOLD)Available RTL Blocks (from filelists/*.rtl.f):$(C_RESET)"
	@(ls -1 filelists/*.rtl.f 2>/dev/null || true) | sed 's|filelists/||;s|.rtl.f||' | sed 's/^/  - /'
	@echo "$(C_BOLD)Available Designer TBs (from filelists/*.tb.f):$(C_RESET)"
	@(ls -1 filelists/*.tb.f 2>/dev/null || true) | sed 's|filelists/||;s|.tb.f||' | sed 's/^/  - /'
	@echo "$(C_BOLD)Available UVM TBs (from filelists/*.uvm.f):$(C_RESET)"
	@(ls -1 filelists/*.uvm.f 2>/dev/null || true) | sed 's|filelists/||;s|.uvm.f||' | sed 's/^/  - /'

TYPE ?= RTL
TYPE_NORM := $(shell echo "$(TYPE)" | tr '[:lower:]' '[:upper:]')

ifeq ($(TYPE_NORM),RTL)
  SV_TOP         := $(TOP_MODULE)
  FILELISTS      := filelists/$(TOP_MODULE).rtl.f
  RTL_PLUSARGS   := $(wildcard filelists/$(TOP_MODULE).defines.f)
  VERILATOR_ARGS := $(wildcard filelists/$(TOP_MODULE).verilator.vlt)
else ifeq ($(TYPE_NORM),TB)
  SV_TOP         := $(TOP_MODULE)_tb
  FILELISTS      := filelists/$(TOP_MODULE).rtl.f filelists/$(TOP_MODULE).tb.f
  RTL_PLUSARGS   := $(wildcard filelists/$(TOP_MODULE).defines.f filelists/$(TOP_MODULE).tb.defines.f filelists/$(SV_TOP).defines.f)
  VERILATOR_ARGS := $(wildcard filelists/$(TOP_MODULE).verilator.vlt filelists/$(TOP_MODULE).tb.verilator.vlt filelists/$(SV_TOP).verilator.vlt)
else ifeq ($(TYPE_NORM),UVM)
  SV_TOP         := $(TOP_MODULE)_tb
  FILELISTS      := filelists/uvm.f filelists/$(TOP_MODULE).rtl.f filelists/$(TOP_MODULE).uvm.f
  RTL_PLUSARGS   := $(wildcard filelists/$(TOP_MODULE).defines.f filelists/$(TOP_MODULE).uvm.defines.f filelists/$(SV_TOP).defines.f)
  VERILATOR_ARGS := $(wildcard filelists/$(TOP_MODULE).verilator.vlt filelists/$(TOP_MODULE).uvm.verilator.vlt filelists/$(SV_TOP).verilator.vlt)
endif

OUTPUT_BASE_DIR = output
LOGS_BASE_DIR = logs
OUTPUT_DIR = $(OUTPUT_BASE_DIR)/$(TOP_MODULE)/$(TYPE_NORM)
LOGS_DIR = $(LOGS_BASE_DIR)/$(TOP_MODULE)/$(TYPE_NORM)
CLEAN_DIRS := obj_dir

ifeq ($(SV_TOP),)
CLEAN_DIRS += $(OUTPUT_BASE_DIR) $(LOGS_BASE_DIR)
CLEAN_MSG  := "CLEAN: ALL"
else ifeq ($(TYPE_NORM),)
CLEAN_DIRS += $(OUTPUT_DIR)/$(TOP_MODULE) $(LOGS_DIR)/$(TOP_MODULE)
CLEAN_MSG  := "CLEAN: $(SV_TOP) (ALL)"
else
CLEAN_DIRS += $(OUTPUT_DIR) $(LOGS_DIR)
CLEAN_MSG  := "CLEAN: $(SV_TOP) ($(TYPE_NORM))"
endif

# Default to one worker so shell startup output cannot corrupt Verilator's -j flag.
# Override on the command line for parallel builds, for example: make build NPROC=8.
# NPROC ?= $(nproc)
NPROC ?= 1
DUMP ?= 1
TEST ?=
PLUSARGS ?=

# --timing \
#	--debug \
# --gdbbt \

VERILATOR_FLAGS += \
	-Wall \
	-j $(NPROC) \
	--top-module $(SV_TOP) \
	$(VERILATOR_ARGS) \
	$(addprefix -f ,$(RTL_PLUSARGS)) \
	$(addprefix -f ,$(FILELISTS))

DUMP_FILE := $(LOGS_DIR)/$(SV_TOP).vcd
RUN_PLUSARGS := $(PLUSARGS)
ifneq ($(TYPE_NORM),RTL)
  ifeq ($(DUMP),1)
    VERILATOR_FLAGS += --trace --trace-structs
    RUN_PLUSARGS += +DUMP +DUMP_FILE=$(DUMP_FILE)
  endif
endif
ifeq ($(TYPE_NORM),UVM)
  ifneq ($(strip $(TEST)),)
    RUN_PLUSARGS += +UVM_TESTNAME=$(TEST)
  endif
endif

.PHONY: help check_vars lint build run clean

# Fail if TOP_MODULE is not defined, TYPE is invalid, or any filelist does not exist
check_vars:
	@if [ -z "$(TOP_MODULE)" ]; then \
		$(echo_error) "TOP_MODULE is not defined."; \
		echo "Usage: make $(MAKECMDGOALS) TOP_MODULE=<module_name> [TYPE={RTL,TB,UVM}]"; \
		exit 1; \
	fi
	@if [ -z "$(filter $(TYPE_NORM),RTL TB UVM)" ]; then \
		$(echo_error) "Invalid TYPE='$(TYPE)'. Expected one of: RTL, TB, UVM."; \
		exit 1; \
	fi
	@for f in $(FILELISTS); do \
		if [ ! -f "$$f" ]; then \
			$(echo_error) "Filelist '$$f' not found for TOP_MODULE=$(TOP_MODULE) (TYPE=$(TYPE_NORM))."; \
			exit 1; \
		fi; \
	done

lint: check_vars
	@$(echo_info) "LINT: $(SV_TOP) ($(TYPE_NORM))"
	@mkdir -p $(LOGS_DIR)
	@$(VERILATOR) --lint-only $(VERILATOR_FLAGS) 2>&1 | tee $(LOGS_DIR)/lint.log $(COLORIZE_LOG)

build: check_vars
ifeq ($(TYPE_NORM),RTL)
	@$(echo_info) "ELABORATE: $(SV_TOP) ($(TYPE_NORM))"
	@mkdir -p $(OUTPUT_DIR) $(LOGS_DIR)
	@$(VERILATOR) --cc $(VERILATOR_FLAGS) -Mdir $(OUTPUT_DIR) 2>&1 | tee $(LOGS_DIR)/verilate.log $(COLORIZE_LOG)
else
	@$(echo_info) "VERILATE: $(SV_TOP) ($(TYPE_NORM))"
	@mkdir -p $(OUTPUT_DIR) $(LOGS_DIR)
	@$(VERILATOR) --binary $(VERILATOR_FLAGS) -Mdir $(OUTPUT_DIR) 2>&1 | tee $(LOGS_DIR)/verilate.log $(COLORIZE_LOG)
endif

run: check_vars
ifeq ($(TYPE_NORM),RTL)
	@$(echo_error) "TYPE=RTL is elaborate-only and cannot be run. Pass TYPE=TB or TYPE=UVM."
	@exit 1
else
	@$(MAKE) --no-print-directory build TOP_MODULE=$(TOP_MODULE) TYPE=$(TYPE_NORM) COLOR=$(COLOR) DUMP=$(DUMP) NPROC=$(NPROC)
	@$(echo_info) "RUN: $(SV_TOP) ($(TYPE_NORM)) $(if $(strip $(RUN_PLUSARGS)),[$(strip $(RUN_PLUSARGS))],)"
	@mkdir -p $(LOGS_DIR)
	@chmod +x $(OUTPUT_DIR)/V$(SV_TOP)
	@rc=0; stdbuf -oL ./$(OUTPUT_DIR)/V$(SV_TOP) $(RUN_PLUSARGS) 2>&1 | tee $(LOGS_DIR)/run.log $(COLORIZE_LOG) || rc=$$?; \
	if [ $$rc -ne 0 ] || grep -Eq '^UVM_(ERROR|FATAL)([[:space:]]+[^:]|[[:space:]]*:[[:space:]]*[1-9])' $(LOGS_DIR)/run.log; then \
		$(echo_error) "RUN ERROR: $(SV_TOP) ($(TYPE_NORM))"; \
		status=1; \
	else \
		$(echo_ok) "RUN SUCCESS: $(SV_TOP) ($(TYPE_NORM))"; \
		status=0; \
	fi; \
	$(echo_info) "  Test:      $(or $(strip $(TEST)),<default>)"; \
	$(echo_info) "  Plusargs:  $(or $(strip $(RUN_PLUSARGS)),<none>)"; \
	$(echo_info) "  Dump file: $(if $(filter 1,$(DUMP)),$(DUMP_FILE),disabled)"; \
	$(echo_info) "  Log file:  $(LOGS_DIR)/run.log"; \
	exit $$status
endif

clean:
	@$(echo_info) $(CLEAN_MSG)
	@$(echo_info) "  Dirs: $(CLEAN_DIRS)"
	@rm -rf $(CLEAN_DIRS)