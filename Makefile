
.PHONY: test test-all test-prove test-concrete \
		build verification tester \
		clean

PROFILE :=

esdt-sources := esdt.md esdt-syntax.md \
				configuration.md containers.md errors.md \
				helpers.md transfer.md  

all: build

build: esdt-kompiled/timestamp 

esdt-kompiled/timestamp: ${esdt-sources}
	kompile esdt.md --backend llvm

verification: verification-kompiled/timestamp

verification-kompiled/timestamp: ${esdt-sources} tests/specs/verification.k 
	kompile tests/specs/verification.k --backend haskell

spec_files := 	tests/specs/functional-spec.k      	 \
	            tests/specs/simple-spec.k      	 \
	            tests/specs/cross-dest-spec.k    \
	            tests/specs/cross-dest-fail-spec.k    \
	            tests/specs/cross-spec.k     	 \
	            tests/specs/cross-return-spec.k     	 \
				tests/specs/issue-simple-spec.k      	 \
	            tests/specs/issue-spec.k      	 \
	            tests/specs/freeze-spec.k      	 \
	            tests/specs/pause-spec.k      	 \
	            tests/specs/upgrade-freeze-spec.k      	 \

test: test-prove test-concrete

test-prove:	$(spec_files:=.prove)

tests/specs/%.prove: verification-kompiled/timestamp 
	$(PROFILE) kprove  tests/specs/$* --definition verification-kompiled

concrete_test_files :=	$(wildcard tests/concrete/*.in.k)

test-concrete: $(concrete_test_files:=.run)

tester: tester-kompiled/timestamp

tester-kompiled/timestamp: ${esdt-sources} tests/concrete/tester.k 
	kompile tests/concrete/tester.k --backend llvm

tests/concrete/%.in.k.run: tester-kompiled/timestamp
	krun --definition tester-kompiled \
		 tests/concrete/$*.in.k \
		 > tests/concrete/$*.out.actual
	diff tests/concrete/$*.out.k tests/concrete/$*.out.actual
	rm tests/concrete/$*.out.actual

clean:
	rm -r .kprove* \
	      .krun* \
		  .kompile* \
	      esdt-kompiled \
	      verification-kompiled \
		  tester-kompiled
