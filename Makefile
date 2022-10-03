
.PHONY: test test-all test-prove

all: build

build: esdt.md
	kompile esdt.md --backend haskell


spec_files := 	tests/specs/simple-spec.k      	 \
	            tests/specs/cross-spec.k     	 \
				tests/specs/issue-spec.k      	 \
	            tests/specs/issue-simple-spec.k	 \

test-prove:	$(spec_files:=.prove)

tests/specs/%.prove: tests/specs/%
	kprove $< 