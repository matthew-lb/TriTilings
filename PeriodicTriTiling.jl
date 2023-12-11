#################### SETUP ####################
include("TriTilings.jl")

@kwdef mutable struct PeriodicTriTiling <: TriTiling
    up_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    down_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    iterate::Function
    get_up::Function
    get_down::Function
    set_up!::Function
    set_down!::Function
    domain_dimensions::Vector{Int64} = [1,1]
end

function periodic_get_up(tiling, x, y; axes = [])
    return tiling.up_configs[x][y]
end

function periodic_get_down(tiling, x, y; axes = [])
    return tiling.down_configs[x][y]
end

#UNSURE WHAT TO DO HERE
function initial_set_up!(tiling,x,y; axes = [])
    tiling.up_configs[x][y] = value
end

#UNSURE WHAT TO DO HERE
function initial_set_down!(tiling,x,y; axes = [])
    tiling.down_configs[x][y] = value
end

function set_up!(tiling, x, y, value; axes = [])
    if tiling.up_configs[x][y] != -1
        tiling.up_configs[x][y] = value
    end
end

function set_down!(tiling, x, y, value; axes = [])
    if tiling.down_configs[x][y] != -1
        tiling.down_configs[x][y] = value
    end
end