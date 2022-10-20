
.PHONY: test test-all test-prove \
		build verification \
		clean

esdt-sources := esdt.md esdt-syntax.md containers.md errors.md

all: build

build: esdt-kompiled/timestamp 

esdt-kompiled/timestamp: ${esdt-sources}
	kompile esdt.md --backend haskell

verification: verification-kompiled/timestamp

verification-kompiled/timestamp: ${esdt-sources} tests/specs/verification.k 
	kompile tests/specs/verification.k --backend haskell

spec_files := 	tests/specs/functional-spec.k      	 \
	            tests/specs/simple-spec.k      	 \
	            tests/specs/cross-dest-spec.k    \
	            tests/specs/cross-dest-fail-spec.k    \
	            tests/specs/cross-spec.k     	 \
				tests/specs/issue-simple-spec.k      	 \
	            tests/specs/issue-spec.k      	 \
	            tests/specs/freeze-spec.k      	 \

test: test-prove

test-prove:	$(spec_files:=.prove)

tests/specs/%.prove: verification-kompiled/timestamp 
	kprove tests/specs/$* --definition verification-kompiled

clean:
	rm -r .kprove* \
	      esdt-kompiled \
		  verification-kompiled