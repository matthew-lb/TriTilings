#################### SETUP ####################
include("TriTilings.jl")

@kwdef mutable struct GenericTriTiling <: TriTiling
    up_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    down_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    iterate::Function
    get_up::Function
    get_down::Function
    set_up!::Function
    set_down!::Function
    domain_dimensions::Vector{Int64} = [1,1]
end

function generic_get_up(tiling, x, y)
    return tiling.up_configs[x][y]
end

function generic_get_down(tiling, x, y)
    return tiling.down_configs[x][y]
end

function initial_set_up!(tiling,x,y,value)
    tiling.up_configs[x][y] = value
end

function initial_set_down!(tiling,x,y,value)
    tiling.down_configs[x][y] = value
end

function generic_set_up!(tiling, x, y, value)
    if tiling.up_configs[x][y] != -1
        tiling.up_configs[x][y] = value
    end
end

function generic_set_down!(tiling, x, y, value)
    if tiling.down_configs[x][y] != -1
        tiling.down_configs[x][y] = value
    end
end