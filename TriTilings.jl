#=
~~~~TriTiling Struct~~~~

Suppose we have a domain in the triangular lattice. We will store this domain in a large paralleogram with sides parallel to _ and \. This paralleogram is sufficiently padded such that no vertex in the domain is on the edge of the paralleogram. For each lattice face in the paralleogram we define it's "configuration value" as follows: 

-1 --> if not all vertices of the triangle lie in the domain
0  --> if none of the edges of the triangle are a dimer
1  --> if the \ edge is a dimer
2  --> if the _ edge is a dimer
3  --> if the / edge is a dimer 

TriTiling.up_configs stores the configuration value of each up face /_\.
TriTiling.down_configs stores the configuration value of each down face \⎻/.
TriTiling.iterate implements a Markov chain update to the tiling
TriTilings.iterator_helper_array stores helper information for the iterator (e.g. where each row of the domain starts for simpler domains)
TriTilings.domain_dimensions = [l,w] where l,w are the dimensions of the large paralleogram the domain will be stored inside of.
TriTilings.composite_domains = Tracks

~~~~TilingConstructor Class~~~~

TilingConstructor.initializer sets up_configs, down_configs to be a valid tiling of some domain. Also sets up helper_array
TilingConstructor.iterator stores information about how to iterate through up/down faces in the desired manner along each axis and coloring
=#

#################### SETUP ####################
using Future, Random

rng_seeds = [Future.randjump(Random.MersenneTwister(0), i*big(10)^20) for i in 1:Threads.nthreads()]

@kwdef mutable struct TriTiling
    up_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    down_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    iterate::Function
    iterator_helper_array::Vector{Vector{Tuple{Int64, Int64}}} = [[(1,1)]]
    domain_dimensions::Vector{Int64} = [1,1]
    composite_domains::Vector{Tuple{Any,Any}} = []
end

space = 1 #Used to prevent false sharing of memory

function get_up(tiling, x, y)
    return tiling.up_configs[x][space*y]
end

function get_down(tiling, x, y)
    return tiling.down_configs[x][space*y]
end

function initial_set_up!(tiling,x,y,value)
    tiling.up_configs[x][space*y] = value
end

function initial_set_down!(tiling,x,y,value)
    tiling.down_configs[x][space*y] = value
end

function set_up!(tiling, x, y, value)
    if tiling.up_configs[x][space*y] != -1
        tiling.up_configs[x][space*y] = value
    end
end

function set_down!(tiling, x, y, value)
    if tiling.down_configs[x][space*y] != -1
        tiling.down_configs[x][space*y] = value
    end
end

#=
function valid_tiling_at(tiling, i,j)
    values = [get_up(tiling,i,j), get_down(tiling,i,j), get_up(tiling,i,j-1), get_down(tiling,i-1,j-1), get_up(tiling,i-1,j-1), get_down(tiling,i-1,j)]
    disconnected = [(values[i] == -1) || (values[i] == 0) || (values[i] == mod(i+1,1:3)) for i in 1:6]
    for i in 1:6
        if all([disconnected[mod(j,1:6)] for j in (i+2):(i+5)])
            if (values[i] == values[mod(i+1,1:6)]) && (values[i] == mod(i,1:3))
                return true
            elseif (values[i] == -1) && (values[mod(i+1,1:6)] == mod(i,1:3))
                return true
            elseif (values[i] == mod(i,1:3)) && (values[mod(i+1,1:6)] == -1)
                return true
            end
        end
    end
    return false
end
=#

function valid_tiling_at(tiling, i,j)
    return lozenge_type_at(tiling, i, j) != 0
end

function lozenge_type_at(tiling, i, j)
    values = [get_up(tiling,i,j), get_down(tiling,i,j), get_up(tiling,i,j-1), get_down(tiling,i-1,j-1), get_up(tiling,i-1,j-1), get_down(tiling,i-1,j)]
    disconnected = [(values[i] == -1) || (values[i] == 0) || (values[i] == mod(i+1,1:3)) for i in 1:6]
    for i in 1:6
        if all([disconnected[mod(j,1:6)] for j in (i+2):(i+5)])
            if (values[i] == values[mod(i+1,1:6)]) && (values[i] == mod(i,1:3))
                return mod(i,1:3)
            elseif (values[i] == -1) && (values[mod(i+1,1:6)] == mod(i,1:3))
                return mod(i,1:3)
            elseif (values[i] == mod(i,1:3)) && (values[mod(i+1,1:6)] == -1)
                return mod(i,1:3)
            end
        end
    end
    return 0
end
