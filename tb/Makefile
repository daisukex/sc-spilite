# -----------------------------------------------------------------------------
#  Copyright 2024 Space Cubics, LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -----------------------------------------------------------------------------

# Simulation Setting
#------------------------
WAVE      := on
TESTCASE  := spil_test

ifdef TESTCASE
	TESTCASE            := --testplusarg \"UVM_TESTNAME=$(TESTCASE)\"
endif

# Command variables
#------------------------
VLOG      := xvlog
SVLOG     := xvlog -sv -L uvm
ELAB      := xelab --timescale 1ps/1ps --debug all -L uvm
SIM       := xsim
MKDIR     := mkdir -p
CPR       := cp -r
RMR       := rm -rf

# Path and File variables
#-------------------------------
DUT_TOP                 := sc_spilite
DUT_LIST_FILE           := ../rtl/sc-spilite.list
DUT_LIST                := $(shell cat $(DUT_LIST_FILE))

TB_TOP                  := tb_top
TB_LIST_FILE            := ./tbench/tb.list
TB_LIST                 := $(shell cat $(TB_LIST_FILE))

INC_DIR                 := tbench tbench/ahb-model
ifdef INC_DIR
	INC_DIR             := $(foreach dir,$(INC_DIR),$(addprefix -i ,$(dir)))
endif

# Simulation Directory and files
#-------------------------------
XDB_DIR                 := xsim.dir
XSIMK_FILE              := $(XDB_DIR)/$(TB_TOP)/xsimk
LOG_DIR                 := simlog
WAV_DIR                 := wave
SIM_SCRIPT              := sim_wave.tcl

# Files to clean
CF                      := $(XDB_DIR) $(LOG_DIR) $(WAV_DIR) xvlog* xsim* xelab* sim_wave.tcl

# vpath for Xilinx-DB
vpath %.sdb $(XDB_DIR)/work



# Simulation target
#==============================

PHONY = all
all: simulation

# Compile DUT and Test Bench
PHONY += dut_compile
dut_compile: $(DUT_TOP).sdb

$(DUT_TOP).sdb: $(DUT_LIST)
	$(MKDIR) $(LOG_DIR)
	$(SVLOG) -log $(LOG_DIR)/dut_compile.log -f $(DUT_LIST_FILE)

PHONY += tb_compile
tb_compile: $(TB_TOP).sdb

$(TB_TOP).sdb: $(TB_LIST)
	$(MKDIR) $(LOG_DIR)
	$(SVLOG) $(INC_DIR) -log $(LOG_DIR)/tb_compile.log -f $(TB_LIST_FILE)


# Elaborate
PHONY += elaborate
elaborate: $(XSIMK_FILE)
$(XSIMK_FILE): $(DUT_TOP).sdb $(TB_TOP).sdb
	$(ELAB) -s $(TB_TOP) --log $(LOG_DIR)/tb_elab.log $(TB_TOP)


# Run Simulation
PHONY += simulation
simulation: $(XSIMK_FILE)
    ifeq ($(WAVE),on)
		$(MKDIR) $(WAV_DIR)
		echo "log_wave -r /; run -all; exit" > $(SIM_SCRIPT)
		$(SIM) --log $(LOG_DIR)/$(TB_TOP)_sim.log -wdb $(WAV_DIR)/$(TB_TOP).wdb -t $(SIM_SCRIPT) $(TESTCASE) $(TB_TOP)
    else
		$(SIM) --log $(LOG_DIR)/$(TB_TOP)_sim.log -R $(TESTCASE) $(TB_TOP)
    endif


# Clean
PHONY += clean
clean:
	$(RMR) $(CF)

.PHONY: $(PHONY)
