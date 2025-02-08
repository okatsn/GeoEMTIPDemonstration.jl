# GeoEMTIPDemonstration

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/dev/)
[![Build Status](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl)

## Introduction

This is a julia package created using `okatsn`'s preference, and this package is registered to [okatsn/OkRegistry](https://github.com/okatsn/OkRegistry).


## Notice: add `GeoEMTIPDemonstration`

Now `GeoEMTIPDemonstration` is a dependency only for the local projects in this repository.
It is currently not a versioned package, and any project outside this repository should not depend on `GeoEMTIPDemonstration`.

For local projects in this repository, take `Project2024` as an example, follow the steps below to add the dependency of `GeoEMTIPDemonstration`.

At workspace (/home/jovyan/workspace where the .git for `GeoEMTIPDemonstration` can be found)
```
(Project2024) pkg> add .
```

## Notice: add a dependency of a private package

Noted that for a private dependency, such as `CWBProjectSummaryDatasets`, please clone it to `~/.julia/dev` first, and then `dev` it.