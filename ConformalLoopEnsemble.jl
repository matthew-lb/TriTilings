include("TriTiling_Markov_Chain.jl")
include("TriTiling_Graphics.jl")
include("MoreDomains.jl")

struct ConformalLoopEnsemble
    loops::Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}
    start_points::Vector{Tuple{Int64, Int64}}
end

struct HeightFunction
    up_heights::Dict{Tuple{Int64, Int64}, Int64}
    down_heights::Dict{Tuple{Int64, Int64}, Int64}
end

function point_set(tiling::TriTiling)
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

function construct_ensemble(tiling::TriTiling; updates = 50, rtiling = nothing)
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
            newpoint = paired_with(tiling, point...)
            loops[point] = newpoint
            i = 1
            while newpoint != point
                if i%2 == 1
                    tempoint = paired_with(rtiling, newpoint...)
                else
                    tempoint = paired_with(tiling, newpoint...)
                end
                loops[newpoint] = tempoint
                newpoint = tempoint
                i += 1
            end
        end
    end

    return ConformalLoopEnsemble(loops, start_points)
end

function is_edge(cle::ConformalLoopEnsemble, p1, p2)
    return (cle.loops[p1] == p2) || (cle.loops[p2] == p1)
end

function single_edge(cle::ConformalLoopEnsemble, p1, p2)
    return (cle.loops[p1] == p2) ⊻ (cle.loops[p2] == p1)
end

function construct_heights(tiling::TriTiling, cle::ConformalLoopEnsemble)
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
            neighbors = [(x,y), (x-1, y), (x, y+1)]
            border = [single_edge(cle, (x,y), (x+1,y+1)), single_edge(cle, (x,y), (x,y+1)), single_edge(cle, (x,y+1), (x+1,y+1))]
            get_func = tiling.get_down
            cur_dict = up_heights
            nb_dict = down_heights   
        else
            neighbors = [(x,y), (x+1,y), (x, y-1)]
            border = [single_edge(cle, (x,y), (x+1,y+1)), single_edge(cle, (x+1,y), (x+1,y+1)), single_edge(cle, (x,y), (x+1, y))]
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
        move(Point(point...))
        line(Point(ce.loops[point]...))
        strokepath()
    end
    finish()
end

