"""
The children of `TrialTable` are used to identify the matching between dataset and trial name.
The matching methods are not general, and should be defined for specific projects; for example,
see load_data.jl in the Project2024.
"""
abstract type TrialTable end

abstract type SummaryJointStation <: TrialTable end

struct PhaseTestEQK <: SummaryJointStation end
struct PhaseTest <: SummaryJointStation end
