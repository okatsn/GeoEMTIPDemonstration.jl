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


## Create sub-projects

Every plotting scripts should not be carried out in the `GeoEMTIPDemonstration`; one should activate a new environment for a task.

For example, here is the step-by-step instruction in creating a plotting task:

- `pkg> activate Project20xx`: create an environment of `Project20xx` for the plot demonstration of the year 20xx.
- `pkg> add .`: Add current repository (i.e., `GeoEMTIPDemonstration`) as the dependency.
> Noted that in `Manifest.toml`, under the dependency of `GeoEMTIPDemonstration` it shows `repo-url = ".."`, denoting that this dependency is located at the parent directory relative to `Project20xx`.









This package is create on 2023-04-14.
