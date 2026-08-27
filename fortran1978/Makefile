# Makefile — Sovereign Apollo 1978 FORTRAN
# Period-appropriate style (gfortran modern compat) — see docs/fortran/15_BUILD_INSTRUCTIONS.md
FC=gfortran
FFLAGS=-std=legacy -O2 -Wall -fdec -ffixed-form
SRC=m_state.f agc_const.f agc_memory.f agc_cpu.f agc_interp.f executive.f orbital.f kepler.f forest_ruth.f propulsion.f control.f vehicle.f timeline.f telemetry.f comms.f engine.f replay.f fault.f verification.f dsky.f main.f
OBJ=$(SRC:.f=.o)

all: sovapol

sovapol: $(OBJ)
	$(FC) $(FFLAGS) -o sovapol $(OBJ)

%.o: %.f
	$(FC) $(FFLAGS) -c $< -o $@

clean:
	rm -f *.o sovapol replay_out.txt

test: sovapol
	./sovapol < /dev/null
	cat replay_out.txt
	@echo "CHK deterministic if two runs match:"
	@./sovapol < /dev/null > /dev/null; CHK1=$$(grep CHK replay_out.txt); ./sovapol < /dev/null > /dev/null; CHK2=$$(grep CHK replay_out.txt); if [ "$$CHK1" = "$$CHK2" ]; then echo "DETERMINISM PASS"; else echo "FAIL"; fi

# Modern compat also via CMake: mkdir build && cmake .. && make
