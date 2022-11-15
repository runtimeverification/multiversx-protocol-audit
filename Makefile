
.PHONY: test test-all test-prove test-concrete \
		build verification tester search \
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

spec_files := $(wildcard tests/specs/*-spec.k)

test: test-prove test-concrete

test-prove:	$(spec_files:=.prove)

tests/specs/%.prove: verification-kompiled/timestamp 
	$(PROFILE) kprove  tests/specs/$* --definition verification-kompiled

concrete_test_files := $(wildcard tests/concrete/*.test)

test-concrete: $(concrete_test_files:=.run)

tester: tester-kompiled/timestamp

tester-kompiled/timestamp: ${esdt-sources} tests/concrete/tester.k 
	kompile tests/concrete/tester.k --backend llvm

tests/concrete/%.test.run: tester-kompiled/timestamp
	krun --definition tester-kompiled tests/concrete/$*.test > tests/concrete/$*.test.out
	rm tests/concrete/$*.test.out

clean:
	rm -r .kprove* \
	      .krun* \
		  .kompile* \
	      esdt-kompiled \
	      verification-kompiled \
		  tester-kompiled
