include("AbstractCompositeTriTiling.jl")

function weighted_composite_iterator(tiling::CompositeTriTiling, update_type::Function; axis::Int64 = 1, color::Int64 = 0, is_up::Bool = true)
    if update_type == update_triangle!
        for (x,y) in tiling.iterator_helper_array[1]
            if rand(rng_seeds[Threads.threadid()]) < triangle_acceptance_probability(tiling, x, y, is_up)
                update_type(tiling, x, y, is_up)
            end
        end
    elseif update_type == update_lozenge!
        for (x,y) in tiling.iterator_helper_array[2*axis + color]
            if rand(rng_seeds[Threads.threadid()]) < lozenge_acceptance_probability(tiling, x, y, axis)
                update_type(tiling, x, y, axis)
            end
        end
    elseif update_type == update_butterfly!
        for (x,y) in tiling.iterator_helper_array[5 + 3*axis + color]
            if rand(rng_seeds[Threads.threadid()]) < butterfly_acceptance_probability(tiling, x, y, axis)
                update_type(tiling, x, y, axis)
            end
        end
    end
end

function weighted_periodic_iterator(tiling::PeriodicCompositeTriTiling, update_type::Function; axis::Int64 = 1, color::Int64 = 0, is_up::Bool = true)
    if update_type == update_triangle!
        for (x,y) in tiling.iterator_helper_array[1]
            if rand(rng_seeds[Threads.threadid()]) < triangle_acceptance_probability(tiling, x, y, is_up)
                update_type(tiling, x, y, is_up)
            end
        end
    elseif update_type == update_lozenge!
        for (x,y) in tiling.iterator_helper_array[1]
            if rand(rng_seeds[Threads.threadid()]) < lozenge_acceptance_probability(tiling, x, y, axis)
                update_type(tiling, x, y, axis)
            end
        end
    elseif update_type == update_butterfly!
        for (x,y) in tiling.iterator_helper_array[1]
            if rand(rng_seeds[Threads.threadid()]) < butterfly_acceptance_probability(tiling, x, y, axis)
                update_type(tiling, x, y, axis)
            end
        end
    end
end

function lozenge_acceptance_probability(tiling::TriTiling, i, j, axis::Int64 = 1)
    if axis == 1
        loz = [(i,j,2), (i,j+1,2)]
        loz_rot = [(i,j,3), (i+1,j,3)]
        reverse = (tiling.get_down(tiling, i, j) == 2) || (tiling.get_up(tiling, i, j-1) == 2)
    elseif axis == 2
        loz = [(i,j,1), (i,j+1,1)]
        loz_rot = [(i,j,3), (i+1,j+1,3)]
        reverse = (tiling.get_down(tiling, i, j) == 1) || (tiling.get_up(tiling, i, j) == 1)
    elseif axis == 3
        loz = [(i-1,j,2), (i,j+1,2)]
        loz_rot = [(i,j,1), (i-1,j,1)]
        reverse = (tiling.get_down(tiling, i-1, j) == 2) || (tiling.get_up(tiling, i-1, j-1) == 2)
    else
        throw(DomainError(axis, "axis can only take values 1,2,3"))
    end
    w = prod([tiling.weight(dimer...) for dimer in loz])
    w_rot = prod([tiling.weight(dimer...) for dimer in loz_rot])
    if reverse
        return w_rot/(w + w_rot)
    end
    return w/(w + w_rot)
end

function triangle_acceptance_probability(tiling::TriTiling, i, j, is_up::Bool = true)
    if is_up 
        loz = [(i, j, 3), (i+1, j+1, 2), (i, j-1, 1)]
        loz_rot = [(i, j-1, 3), (i+1, j, 1), (i, j+1, 2)]
        reverse = (tiling.get_up(tiling, i, j) == 3) || (tiling.get_down(tiling, i-1, j) == 3)
    else
        loz = [(i, j, 2), (i+1, j+1, 3), (i-1, j, 1)]
        loz_rot = [(i-1, j, 2), (i+1, j, 3), (i, j+1, 1)]
        reverse = (tiling.get_down(tiling, i, j) == 2) || (tiling.get_up(tiling, i, j-1) == 2)
    end
    w = prod([tiling.weight(dimer...) for dimer in loz])
    w_rot = prod([tiling.weight(dimer...) for dimer in loz_rot])
    if reverse
        return w_rot/(w + w_rot)
    end
    return w/(w + w_rot)
end

function butterfly_acceptance_probability(tiling::TriTiling, i, j, axis::Int64 = 1)
    if axis == 1
        loz = [(i, j-1, 3), (i+1, j+1, 3), (i-1, j, 1), (i+1, j, 1)]
        loz_rot =  [(i, j-1, 1), (i-1, j, 2), (i+1, j+1, 2), (i, j+1, 1)]
        reverse = (tiling.get_down(tiling,i-1,j-1) == 3) || (tiling.get_up(tiling,i,j-1) == 3)
    elseif axis == 2
        loz = [(i-1, j, 2), (i+1, j, 3), (i, j+1, 3), (i+1, j+2, 2)]
        loz_rot =  [(i, j, 2), (i-1, j, 1), (i+1, j+1, 1), (i, j+2 ,2)]
        reverse = (tiling.get_down(tiling,i-1,j) == 2) || (tiling.get_up(tiling,i-1,j-1) == 2)
    elseif axis == 3
        loz = [(i, j, 2), (i+1, j+1, 3), (i-1, j-1, 3), (i-1, j+1, 2)]
        loz_rot = [(i-1, j-1, 1), (i+1, j, 3), (i, j+1, 1), (i-1, j, 3)]
        reverse = (tiling.get_down(tiling, i, j) == 2) || (tiling.get_up(tiling, i, j-1) == 2)
    else
        throw(DomainError(axis, "axis can only take values 1,2,3"))
    end
    w = prod([tiling.weight(dimer...) for dimer in loz])
    w_rot = prod([tiling.weight(dimer...) for dimer in loz_rot])
    if reverse
        return w_rot/(w + w_rot)
    end
    return w/(w + w_rot)
end

function one_periodic_weight(p,q,r, i, j, axis)
    if axis == 1
        return p
    elseif axis == 2
        return q
    elseif axis == 3
        return r
    end
end

function color_weight(p,q,r, i, j, axis)
    if (axis == 1) && ((i+j)%2 == 0)
        return p
    elseif (axis == 2) && (j%2 == 0)
        return q
    elseif (axis == 3) && (i%2 == 0)
        return r
    end
    return 1
end