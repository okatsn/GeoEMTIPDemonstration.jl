# GeoEMTIPDemonstration

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/dev/)
[![Build Status](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl)

<!-- Don't have any of your custom contents above; they won't occur if there is no citation. -->

## Introduction

This is a julia package created using `okatsn`'s preference, and this package is expected to be registered to [okatsn/OkRegistry](https://github.com/okatsn/OkRegistry) for CIs to work properly.

!!! note Checklist
    - [ ] Create an empty repository (namely, `https://github.com/okatsn/GeoEMTIPDemonstration.jl.git`) on github, and push the local to origin. See [connecting to remote](#tips-for-connecting-to-remote).
    - [ ] Add `ACCESS_OKREGISTRY` secret in the settings of this repository on Github, or delete both `register.yml` and `TagBot.yml` in `/.github/workflows/`. See [Auto-Registration](#auto-registration).


### Go to [OkPkgTemplates](https://github.com/okatsn/OkPkgTemplates.jl) for more information
- [How TagBot works and trouble shooting](https://github.com/okatsn/OkPkgTemplates.jl#tagbot)
- [Use of Documenter](https://github.com/okatsn/OkPkgTemplates.jl#use-of-documenter)

## References

### Auto-Registration
- You have to add `ACCESS_OKREGISTRY` to the secret under the remote repo (e.g., https://github.com/okatsn/GeoEMTIPDemonstration.jl).
- `ACCESS_OKREGISTRY` allows `CI.yml` to automatically register/update this package to [okatsn/OkRegistry](https://github.com/okatsn/OkRegistry).

### Test
#### How to add a new test
Add `.jl` files (that has `@testset` block or `@test` inside) in `test/`; `test/runtests.jl` will automatically `include` all the `.jl` scripts there.

#### Test docstring
`doctest` is executed at the following **two** places:
1. In `CI.yml`, `jobs: test: ` that runs `test/runtests.jl`
2. In `CI.yml`, `jobs: docs: ` that runs directly on bash.

It is no harm to run both, but you can manually delete either.
Of course, `pkg> test` will also run `doctest` since it runs also `test/runtests.jl`.

### Tips for connecting to remote
Connect to remote:
1. Switch to the local directory of this project (GeoEMTIPDemonstration)
2. Add an empty repo GeoEMTIPDemonstration(.jl) on github (without anything!)
3. `git push origin main`
- It can be quite tricky, see https://discourse.julialang.org/t/upload-new-package-to-github/56783
More reading
Pkg's Artifact that manage an external dataset as a package
- https://pkgdocs.julialang.org/v1/artifacts/
- a provider for reposit data: https://github.com/sdobber/FA_data


This package is create on 2023-04-14.
