# ESDT

## Running proofs

```
# make {path-to-spec.k}.prove
make tests/specs/simple-spec.k.prove PROFILE='./profile log timeout 3000'
```

With profiling:

```
make tests/specs/simple-spec.k.prove PROFILE='./profile log timeout 3000'
```