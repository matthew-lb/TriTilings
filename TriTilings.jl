#=
~~~~TriTiling Type~~~~

Suppose we have a domain in the triangular lattice. We will store this domain in a large paralleogram with sides parallel to _ and \. This paralleogram is sufficiently padded such that no vertex in the domain is on the edge of the paralleogram. For each lattice face in the paralleogram we define it's "configuration value" as follows: 

-1 --> if not all vertices of the triangle lie in the domain
0  --> if none of the edges of the triangle are a dimer
1  --> if the \ edge is a dimer
2  --> if the _ edge is a dimer
3  --> if the / edge is a dimer 

All structs with type TriTiling will be expected to have the following values

TriTiling.up_configs stores the configuration value of each up face /_\.
TriTiling.down_configs stores the configuration value of each down face \⎻/.
TriTiling.iterate implements a Markov chain update to the tiling
TriTiling.set_up! changes a value in TriTiling.up_configs
TriTiling.set_down! changes a value in TriTiling.down_configs
TriTiling.get_up retrieves a value in TriTiling.up_configs
TriTiling.get_down retreives a value in TriTiling.down_configs
TriTiling.domain_dimensions stores dimensions of large parallelogram
=#

#################### SETUP ####################
using Future, Random

rng_seeds = [Future.randjump(Random.MersenneTwister(0), i*big(10)^20) for i in 1:Threads.nthreads()]

abstract type TriTiling end


function paired_direction(tiling, i, j)
    values = [tiling.get_up(tiling,i,j), tiling.get_down(tiling,i,j), tiling.get_up(tiling,i,j-1), tiling.get_down(tiling,i-1,j-1), tiling.get_up(tiling,i-1,j-1), tiling.get_down(tiling,i-1,j)]
    disconnected = [(values[i] == -1) || (values[i] == 0) || (values[i] == mod(i+1,1:3)) for i in 1:6]
    for i in 1:6
        if all([disconnected[mod(j,1:6)] for j in (i+2):(i+5)])
            if (values[i] == values[mod(i+1,1:6)]) && (values[i] == mod(i,1:3))
                return i
            elseif (values[i] == -1) && (values[mod(i+1,1:6)] == mod(i,1:3))
                return i
            elseif (values[i] == mod(i,1:3)) && (values[mod(i+1,1:6)] == -1)
                return i
            end
        end
    end
    return 0
end

function paired_with(tiling, i, j)
    r = paired_direction(tiling, i, j)
    if r == 0
        throw(ErrorException("Not a valid tiling"))
    elseif r == 1
        return i+1,j+1
    elseif r == 2
        return i+1,j
    elseif r == 3
        return i,j-1
    elseif r == 4
        return i-1,j-1
    elseif r == 5
        return i-1,j
    else
        return i,j+1
    end
end

function lozenge_type_at(tiling, i, j)
    pd = paired_direction(tiling, i, j)
    if pd == 0
        return 0
    end
    return mod(pd,1:3)
end

function valid_tiling_at(tiling, i,j)
    return paired_direction(tiling, i, j) != 0
end

#sub_domain will be a collection of points relative to [0,0]
#implement first w/o error handling

function is_subdomain_of(tiling, sub_domain, i, j)
    for (x,y) in sub_domain
        xp,yp = paired_with(tiling, x+i, y+j)
        xp -= i
        yp -= j
        if !((xp, yp) in sub_domain)
            return false
        end
    end
    return true
end
