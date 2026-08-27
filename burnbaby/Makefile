# Makefile — Sovereign Apollo BURNBABY
# Builds the three standalone Fortran programs and the ALU module+demo.
# Requires: gfortran (any version supporting -std=f2008)

FC      = gfortran
FFLAGS  = -std=f2008 -O2 -Wall -Wextra -ffree-line-length-none
FDIR    = fortran

.PHONY: all clean test

all: manoeuvre_time burnbaby_demo alu_demo

# ── Standalone programs ────────────────────────────────────────────────────

manoeuvre_time: $(FDIR)/manoeuvre_time.f90
	$(FC) $(FFLAGS) $< -o $@

burnbaby_demo: $(FDIR)/burnbaby.f90
	$(FC) $(FFLAGS) $< -o $@

# ALU module is compiled first; demo driver uses it via host association
# (both are in the same source file — the program follows the module)
alu_demo: $(FDIR)/agc_alu_parity.f90
	$(FC) $(FFLAGS) $< -o $@

# ── Quick smoke tests ─────────────────────────────────────────────────────

test: all
	@echo "--- manoeuvre_time ---"
	./manoeuvre_time
	@echo "--- burnbaby_demo ---"
	./burnbaby_demo
	@echo "--- alu_demo ---"
	./alu_demo
	@echo "All tests passed."

# ── Lean verification (requires lake + Mathlib) ───────────────────────────

lean-check:
	cd lean && lake build

clean:
	rm -f manoeuvre_time burnbaby_demo alu_demo *.mod *.o
