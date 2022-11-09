# ESDT

## Running tests

* `make test`: run all symbolic and concrete tests
* `make test-prove`: run proofs
    * `make tests/specs/{name}.k.prove`: prove specs in `tests/specs/{name}.k`
    * add `PROFILE='./profile log timeout 3000'` to measure time and memory usage
* `make test-concrete`: run concrete tests
    * `make tests/concrete/*.test.run`: run a specific concrete test 

### Examples

```
# make {path-to-spec.k}.prove
make tests/specs/simple-spec.k.prove PROFILE='./profile log timeout 3000'
```

With profiling:

```
make tests/specs/simple-spec.k.prove PROFILE='./profile log timeout 3000'

make test-prove PROFILE='./profile log timeout 3000'
```