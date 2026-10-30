# Conformance fixtures

Shared test cases for every Framework engine: the R package, the Python
package, and `fw` (which merges layers for Stata scaffolding). They pin down
behavior that must be identical across languages.

## merge/

Each file is one case of the layer merge that `spec_resolve()` performs
before applying a language's package defaults and finalizing the spec.

- `layers` is the input, in the `layers` format of `layers.v1.json`: a list
  of `{kind, key, version, layer}` entries. An entry without `kind` is
  labeled `layer N` (1-based); otherwise the label is `kind`, then `key`, then
  `vN` when `version` is set, separated by spaces.
- `expected.spec` is the merged result with no package defaults. The
  `git.gitignore_content` text is removed from it and reported separately.
- `expected.gitignore_blocks` lists each layer's gitignore text with its
  label, in layer order.
- `expected.conflicts` lists keys set to different values by more than one
  layer. `path` joins keys with `/`, and `layers` joins the labels with `, `.

Compare as parsed JSON, with these rules:

- Object key order does not matter.
- An empty object `{}` equals an empty array `[]` (R cannot tell them apart).
- Conflicts are compared as a set.

## Updating

The inputs are written by hand. The expected outputs are generated from the
R implementation by `data-raw/conformance.R` and reviewed before committing.
A change to the merge rules changes these files in the same commit, and the
Python package and `fw` update their pinned copies from the release tag.
