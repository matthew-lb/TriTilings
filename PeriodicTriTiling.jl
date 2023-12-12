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

function shift_in_bounds(tiling, x, y)
    if y <= 0
        y += tiling.domain_dimensions[1] - tiling.shift[1]
    elseif y > tiling.domain_dimensions[1]
        y -= tiling.domain_dimensions[1] - tiling.shift[1]
    end
    if x <= 0
        x += tiling.domain_dimensions[2] - tiling.shift[2]
    elseif x > tiling.domain_dimensions[2]
        x -= tiling.domain_dimensions[2] - tiling.shift[2]
    end
    return (x,y)
end

function periodic_get_up(tiling, x, y; axes = [])
    x,y = shift_in_bounds(tiling, x, y)
    return tiling.up_configs[x][y]
end

function periodic_get_down(tiling, x, y; axes = [])
    x,y = shift_in_bounds(tiling, x, y)
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

function periodic_set_up!(tiling, x, y, value; axes = [])
    x,y = shift_in_bounds(tiling, x, y)
    if tiling.up_configs[x][y] != -1
        tiling.up_configs[x][y] = value
    end
end

function periodic_set_down!(tiling, x, y, value; axes = [])
    x,y = shift_in_bounds(tiling, x, y)
    if tiling.down_configs[x][y] != -1
        tiling.down_configs[x][y] = value
    end
end