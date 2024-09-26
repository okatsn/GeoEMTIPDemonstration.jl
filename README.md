# GeoEMTIPDemonstration

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://okatsn.github.io/GeoEMTIPDemonstration.jl/dev/)
[![Build Status](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/okatsn/GeoEMTIPDemonstration.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/okatsn/GeoEMTIPDemonstration.jl)

<!-- Don't have any of your custom contents above; they won't occur if there is no citation. -->

## Introduction

This is a julia package created using `okatsn`'s preference, and this package is registered to [okatsn/OkRegistry](https://github.com/okatsn/OkRegistry).

This is a package specifically for TIP summaries demonstration.

!!! warn 
    - Do not include any secrets or sensitive information in the comment.


## Creating Sub-Projects

Plotting scripts should not be executed directly within `GeoEMTIPDemonstration`; instead, a new environment should be activated for each task.

Here's a step-by-step guide for setting up a plotting task:

- `pkg> activate Project20xx`: Activate the environment for `Project20xx`, which corresponds to the plot demonstration for the year 20xx.
- `pkg> add .`: Add the current repository (i.e., `GeoEMTIPDemonstration`) as a dependency for `Project20xx`.
> Note: In `Manifest.toml` of `Project20xx`, under the dependency for `GeoEMTIPDemonstration`, you will see `repo-url = ".."`, indicating that this dependency is located in the parent directory relative to `Project20xx`.









This package is create on 2023-04-14.
