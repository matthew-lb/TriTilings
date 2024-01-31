include("TriTiling_Markov_Chain.jl")
include("TriTiling_Graphics.jl")
include("MoreDomains.jl")

struct ConformalLoopEnsemble
    loops::Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}
    start_points::Vector{Tuple{Int64, Int64}}
    periodic::Bool
end

struct HeightFunction
    up_heights::Dict{Tuple{Int64, Int64}, Int64}
    down_heights::Dict{Tuple{Int64, Int64}, Int64}
end

function point_set(tiling::CompositeTriTiling)
    appeared = Set{Tuple{Int64, Int64}}()
    for (x,y) in tiling.iterator_helper_array[1]
        if tiling.get_up(tiling, x, y) != -1
            push!(appeared, (x,y))
            push!(appeared, (x,y+1))
            push!(appeared, (x+1,y+1))
        end
        if tiling.get_down(tiling, x, y) != -1
            push!(appeared, (x,y))
            push!(appeared, (x+1,y))
            push!(appeared, (x+1,y+1))
        end
    end
    return appeared
end

function point_set(tiling::PeriodicCompositeTriTiling)
    appeared = Set{Tuple{Int64, Int64}}()
    for (x,y) in tiling.iterator_helper_array[1]
        if tiling.get_up(tiling, x, y) != -1
            push!(appeared, (x,y))
            push!(appeared, shift_in_bounds(tiling, x,y+1))
            push!(appeared, shift_in_bounds(tiling, x+1,y+1))
        end
        if tiling.get_down(tiling, x, y) != -1
            push!(appeared, (x,y))
            push!(appeared, shift_in_bounds(tiling, x+1,y))
            push!(appeared, shift_in_bounds(tiling, x+1,y+1))
        end
    end
    return appeared
end

function neighbor_to(tiling::CompositeTriTiling, i, j)
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

function neighbor_to(tiling::PeriodicCompositeTriTiling, i, j)
    r = paired_direction(tiling, i, j)
    if r == 0
        throw(ErrorException("Not a valid tiling"))
    elseif r == 1
        return shift_in_bounds(tiling, i+1,j+1)
    elseif r == 2
        return shift_in_bounds(tiling, i+1,j)
    elseif r == 3
        return shift_in_bounds(tiling, i,j-1)
    elseif r == 4
        return shift_in_bounds(tiling, i-1,j-1)
    elseif r == 5
        return shift_in_bounds(tiling, i-1,j)
    else
        return shift_in_bounds(tiling, i,j+1)
    end
end


function construct_ensemble(tiling::AbstractCompositeTriTiling; updates = 50, rtiling = nothing)
    if isnothing(rtiling)
        rtiling = deepcopy(tiling)
        for i in 1:updates
            systematic_update!(rtiling)
        end
    end
    points = point_set(tiling::TriTiling)
    loops = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}()
    start_points = Vector{Tuple{Int64, Int64}}()
    for point in points
        if !haskey(loops, point)
            push!(start_points, point)
            newpoint = neighbor_to(tiling, point...)
            loops[point] = newpoint
            i = 1
            while newpoint != point
                if i%2 == 1
                    tempoint = neighbor_to(rtiling, newpoint...)
                else
                    tempoint = neighbor_to(tiling, newpoint...)
                end
                loops[newpoint] = tempoint
                newpoint = tempoint
                i += 1
            end
        end
    end
    return ConformalLoopEnsemble(loops, start_points, isa(tiling, PeriodicCompositeTriTiling))
end

function is_edge(cle::ConformalLoopEnsemble, p1, p2)
    return (cle.loops[p1] == p2) || (cle.loops[p2] == p1)
end

function single_edge(cle::ConformalLoopEnsemble, p1, p2)
    return (cle.loops[p1] == p2) ⊻ (cle.loops[p2] == p1)
end

function construct_heights(tiling::AbstractCompositeTriTiling, cle::ConformalLoopEnsemble)
    up_heights = Dict{Tuple{Int64, Int64}, Int64}()
    down_heights = Dict{Tuple{Int64, Int64}, Int64}()
    if tiling.get_up(tiling, tiling.iterator_helper_array[1][1]...) != -1
        start_face = (tiling.iterator_helper_array[1][1], true)
        push!(up_heights, start_face[1] => 0)
    else
        start_face = (tiling.iterator_helper_array[1][1], false)
        push!(down_heights, start_face[1] => 0)
    end
    stack = [start_face]
    while length(stack) > 0
        face, is_up = pop!(stack)
        x,y = face
        if is_up
            if !cle.periodic
                neighbors = [(x,y), (x-1, y), (x, y+1)]
                border = [single_edge(cle, (x,y), (x+1,y+1)), 
                          single_edge(cle, (x,y), (x,y+1)), 
                          single_edge(cle, (x,y+1), (x+1,y+1))]
            else
                neighbors = [shift_in_bounds(tiling,x,y), shift_in_bounds(tiling,x-1, y), shift_in_bounds(tiling, x, y+1)]
                border = [single_edge(cle, shift_in_bounds(tiling, x,y), shift_in_bounds(tiling, x+1,y+1)), 
                          single_edge(cle, shift_in_bounds(tiling, x,y), shift_in_bounds(tiling, x,y+1)), 
                          single_edge(cle, shift_in_bounds(tiling, x,y+1), shift_in_bounds(tiling, x+1,y+1))]
            end
            get_func = tiling.get_down
            cur_dict = up_heights
            nb_dict = down_heights   
        else
            if !cle.periodic
                neighbors = [(x,y), (x+1,y), (x, y-1)]
                border = [single_edge(cle, (x,y), (x+1,y+1)), 
                          single_edge(cle, (x+1,y), (x+1,y+1)), 
                          single_edge(cle, (x,y), (x+1, y))]
            else
                neighbors = [shift_in_bounds(tiling,x,y), shift_in_bounds(tiling,x+1,y), shift_in_bounds(tiling, x, y-1)]
                border = [single_edge(cle, shift_in_bounds(tiling, x,y), shift_in_bounds(tiling, x+1,y+1)), 
                          single_edge(cle, shift_in_bounds(tiling, x+1,y), shift_in_bounds(tiling, x+1,y+1)), 
                          single_edge(cle, shift_in_bounds(tiling, x,y), shift_in_bounds(tiling, x+1,y))]
            end
            get_func = tiling.get_up
            cur_dict = down_heights
            nb_dict = up_heights
        end
        for i in 1:3
            height = cur_dict[face]
            if border[i] height = (height+1)%2 end
            if !haskey(nb_dict, neighbors[i])
                push!(nb_dict, neighbors[i] => height)
                if get_func(tiling, neighbors[i]...) != -1 #if interior face
                    push!(stack, (neighbors[i], !is_up))
                end
            end
        end
    end
    return HeightFunction(up_heights, down_heights)
end

function loop_lengths(cle::ConformalLoopEnsemble)
    lengths = []
    for point in cle.start_points
        l = 1
        newpoint = cle.loops[point]
        while newpoint != point
            newpoint = cle.loops[newpoint]
            l += 1
        end
        push!(lengths, l)
    end
    return sort(lengths)
end

function save_loops_to_luxor_file(ce::ConformalLoopEnsemble, filename; xdim = 100, ydim = 100, ht::HeightFunction = nothing, fill_ht = false)
    Drawing(xdim, ydim, "img/"*filename)
    if fill_ht
        for (x,y) in keys(ht.up_heights)
            col = if ht.up_heights[(x,y)] == 0 "orange" else "blue" end
            move(Point(x,y))
            line(Point(x+1,y+1))
            line(Point(x,y+1))
            closepath()
            setcolor(col)
            fillpath()
        end
        for (x,y) in keys(ht.down_heights)
            col = if ht.down_heights[(x,y)] == 0 "orange" else "blue" end
            move(Point(x,y))
            line(Point(x+1,y))
            line(Point(x+1,y+1))
            closepath()
            setcolor(col)
            fillpath()
        end
    end
    setcolor("black")
    setline(.2)
    for point in keys(ce.loops)
        if abs(point[1] - ce.loops[point][1]) <= 1 && abs(point[2] - ce.loops[point][2]) <= 1
            move(Point(point...))
            line(Point(ce.loops[point]...))
            strokepath()
        end
    end
    finish()
end

function magnetization(ht::HeightFunction)
    return sum(values(ht.up_heights)) + sum(values(ht.down_heights)) - length(values(ht.up_heights))
end

function interaction(tiling::AbstractCompositeTriTiling, rtiling::AbstractCompositeTriTiling)
    interaction = 0
    for j in 1:tiling.domain_dimensions[1]
        for i in 1:tiling.domain_dimensions[2]
            for get_func in [tiling.get_up, tiling.get_down]
                if get_func(tiling, i, j) != -1
                    if get_func(tiling, i, j) == get_func(rtiling, i, j)
                        interaction += 3
                    elseif (get_func(tiling, i, j) == 0) || (get_func(rtiling, i, j) == 0)
                        interaction += 1
                    else
                        interaction -= 1
                    end
                end
            end
        end
    end
    return interaction
end

