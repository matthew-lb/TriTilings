#=
~~~~Construction of General Domains~~~~

(I) Iteration
General Domains will be constructed to be unions of simpler tileable domains (e.g. parallelograms, trapezoids, etc.) that do not share any points. The idea behind the algorithm is to randomly update the domain using lozenge/triangle/butterfly type moves. In order to do as many of these moves in parallel as possible we need various coloring schemes. Along each axis we need 1 color for triangle moves, 2 colors for lozenge moves, and 3 colors for butterfly moves. Each iteration we can pick a move type and conduct all moves with a fixed axis/color in parallel.

In order to conduct all such moves in paralle, each entry of Tiling.iterator_helper_array will store all elements that have a particular axis/color. In particular:
- Tiling.iterator_helper_array[1] = full list of all coordinates whose up or down face is non-negative
- Tiling.iterator_helper_array[2*axis + bicolor] = full list of all coordinates along axis that have bicolor
- Tiling.iterator_helper_array[5+3*axis + tricolor] = full list of all coordinates along axis with tricolor

(II) Merging Domains
For each domain there will be a corresponding function add_domain that implements adding a domain to our region at a specific location. For example
    add_parallelogram(tiling::TriTiling, l::Int64, w::Int64, x::Int64, y::Int64)
will add a wxl parallelogram to tiling with top left corner at (x,y). 

add_domain establish:
 (1) Add all points of the domain to the relevant entries of Tiling.iterator_helper_array
 (2) Set the values of up_configs/down_configs to a "temporary configuration value". The temporary_configuration value at up_configs[x][y] be a 6 digit binary string abcdef. The digits of this string correspond to the following:
    1's place  - Dimer along axis 1
    2's place  - Dimer along axis 2
    4's place  - Dimer along axis 4
    8's place  - Coordinate (x,y) lies in the domain
    16's place - Coordinate clockwise from (x,y) lies in the domain
    32's place - Coordinate anticlockwise from (x,y) lies in the domain 

The reason for the "temporary configuration values" is that a face can lie in the unioned domain but not lie in any subdomain. add_domain will pick a generic tiling of the region.

(III) Initalizer 
The initalizer for composite domains will be composite_initalizer which will 
    (1) set up_configs, down_configs to have all values equal to 0, 
    (2) call each add_domain with the relevant parameters, 
    (3) convert all temporary configuration values to normal configuration values.
    (4) set values of iterator_helper_array 
Steps (4), (5) will be accomplished by the function convert_temporary_configurations
=#

using .Threads
include("TriTilings.jl")

#################### KEY FUNCTIONALITY ####################


function add_to_iterator_helper!(tiling::TriTiling, x::Int64, y::Int64)
    push!(tiling.iterator_helper_array[1], (x,y))
    for axis in 1:3
        if axis == 1
            col = x - y
        elseif axis == 2
            col = y
        elseif axis == 3
            col = x
        end
        push!(tiling.iterator_helper_array[2*axis + mod(col,0:1)], (x,y))
        push!(tiling.iterator_helper_array[5 + 3*axis + mod(col,0:2)], (x,y))
    end
end

function convert_temporary_configurations!(tiling::TriTiling)
    l,w = tiling.domain_dimensions
    for x in 1:w for y in 1:l
        add_to_iterator = false
        if tiling.up_configs[x][y] < 56
            tiling.up_configs[x][y] = -1
        elseif !((tiling.up_configs[x][y] & 7) in [0,1,2,4])
            throw(ArgumentError("Domains cannot be merged--one vertex ends up matched to multiple vertices"))
        else
            add_to_iterator = true
            tiling.up_configs[x][y] = tiling.up_configs[x][y] & 7
            if tiling.up_configs[x][y] == 4
                tiling.up_configs[x][y] = 3
            end
        end
        if tiling.down_configs[x][y] < 56
            tiling.down_configs[x][y] = -1
        elseif !((tiling.down_configs[x][y] & 7) in [0,1,2,4])
            throw(ArgumentError("Domains cannot be merged--one vertex ends up matched to multiple vertices"))
        else
            add_to_iterator = true
            tiling.down_configs[x][y] = tiling.down_configs[x][y] & 7
            if tiling.down_configs[x][y] == 4
                tiling.down_configs[x][y] = 3
            end
        end
        if add_to_iterator
            add_to_iterator_helper!(tiling, x, y)
        end
    end
    end
end

function composite_initalizer!(tiling::TriTiling)
    #We will assume domain_dimensions, composite_domains have been set
    l,w = tiling.domain_dimensions
    tiling.iterator_helper_array = [[] for _ in 1:16]
    tiling.up_configs = [[0 for _ in 1:l] for _ in 1:w]
    tiling.down_configs = [[0 for _ in 1:l] for _ in 1:w]
    for (add_domain, inputs) in tiling.composite_domains
        add_domain(tiling, inputs...)
    end
    convert_temporary_configurations!(tiling)
end

function composite_iterator(tiling::TriTiling, update_type::Function; axis::Int64 = 1, color::Int64 = 0, is_up::Bool = true)
    if update_type == update_triangle!
        for (x,y) in tiling.iterator_helper_array[1]
            update_type(tiling, x, y, is_up)
        end
    elseif update_type == update_lozenge!
        for (x,y) in tiling.iterator_helper_array[2*axis + color]
            update_type(tiling, x, y, axis)
        end
    elseif update_type == update_butterfly!
        for (x,y) in tiling.iterator_helper_array[5 + 3*axis + color]
            update_type(tiling, x, y, axis)
        end
    end
end

#################### SIMPLE DOMAINS ####################

function add_axis_one_line!(tiling::TriTiling, l::Int64, x::Int64, y::Int64)
    if l%2 != 1
        throw(DomainError((l,1), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:l
        tiling.down_configs[x+i-1][y+i] |= 16
        tiling.up_configs[x+i][y+i-1] |= 32
    end
    for i in 0:(l-1)
        tiling.up_configs[x+i][y+i] |= 24 #8+16
        tiling.down_configs[x+i][y+i] |= 40 #8+32
    end
    tiling.down_configs[x-1][y-1] |= 32
    tiling.up_configs[x-1][y-1] |= 16
    tiling.up_configs[x+l][y+l] |= 8
    tiling.up_configs[x+l][y+l] |= 8
    #Set 1,2,4 components
    for i in 0:2:(l-1)
        tiling.up_configs[x+i][y+i] |= 1
        tiling.down_configs[x+i][y+i] |= 1
    end
end

function add_axis_two_line!(tiling::TriTiling, w::Int64, x::Int64, y::Int64)
    #w refers to length not number of points
    if w%2 != 1
        throw(DomainError((1,w), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:w
        tiling.up_configs[x+i][y] |= 8
        tiling.down_configs[x+i-1][y-1] |= 32
    end
    for i in 0:(w-1)
        tiling.down_configs[x+i][y] |= 24 #8+16
        tiling.up_configs[x+i][y-1] |= 48 #16+32
    end
    tiling.up_configs[x-1][y-1] |= 16
    tiling.down_configs[x-1][y] |= 16
    tiling.up_configs[x+w][y-1] |= 32
    tiling.down_configs[x+w][y] |= 8
    #Set 1,2,4 components
    for i in 0:2:(w-1)
        tiling.up_configs[x+i][y-1] |= 2
        tiling.down_configs[x+i][y] |= 2
    end
end

function add_axis_three_line!(tiling::TriTiling, l::Int64, x::Int64, y::Int64)
    if l%2 != 1
        throw(DomainError((l,1), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:l
        tiling.down_configs[x][y+i] |= 8
        tiling.up_configs[x-1][y+i-1] |= 16
    end
    for i in 0:(l-1)
        tiling.down_configs[x-1][y+i] |= 48 #8+16
        tiling.up_configs[x][y+i] |= 40 #16+32
    end
    tiling.down_configs[x-1][y-1] |= 32
    tiling.up_configs[x][y-1] |= 32
    tiling.up_configs[x][y+l] |= 8
    tiling.down_configs[x-1][y+l] |= 16
    #Set 1,2,4 components
    for i in 0:2:(l-1)
        tiling.up_configs[x][y+i] |= 4
        tiling.down_configs[x-1][y+i] |= 4
    end
end

function add_parallelogram!(tiling::TriTiling, l::Int64, w::Int64, x::Int64, y::Int64, axis::Int64)
    if (l%2 == 0) && (w%2 == 0)
        throw(DomainError((l,w), "No tiling of the domain with such side lengths exists"))
    end
    if axis == 1
        if w%2 == 1
            for j in 0:l
                add_axis_two_line!(tiling, w, x, y+j)
            end
        else
            for i in 0:w
                add_axis_three_line!(tiling, l, x+i, y)
            end
        end
    elseif axis == 2
        if w%2 == 1
            for j in 0:l
                add_axis_one_line!(tiling, w, x, y - j)
            end
        else
            for i in 0:w
                add_axis_three_line!(tiling, l, x+i, y-l+i)
            end
        end
    elseif axis == 3
        if w%2 == 1
            for j in 0:l
                add_axis_two_line!(tiling, w, x+j, y+j)
            end
        else
            for i in 0:w
                add_axis_one_line!(tiling, l, x+i, y)
            end
        end
    end
end

function add_rectangle_helper!(tiling::TriTiling, w::Int64, x::Int64, y::Int64, odd = true)
    if w%2 != 0
        throw(DomainError((3,w), "No tiling of the domain (rectangle) with such side lengths exists"))
    end
    add_axis_two_line!(tiling, 1, x, y)
    add_axis_three_line!(tiling, 1, x+1, y+1)
    add_axis_three_line!(tiling, 1, x+w, y)
    add_axis_two_line!(tiling, 1, x+w, y+2)
    add_parallelogram!(tiling, 2, w - 3, x+2, y, 1)
    if !odd
        add_axis_two_line!(tiling, w-1, x+2, y+3)
    end
end

function add_rectangle!(tiling::TriTiling, l::Int64, w::Int64, x::Int64, y::Int64)
    if (w%2 != 0) || (l%4 == 2) || (l%4 == 1)
        throw(DomainError((l,w), "No tiling of the domain (rectangle) with such side lengths exists"))
    end
    for i in 0:(div(l,4) - 1)
        add_rectangle_helper!(tiling, w, x + 2*i, y + 4*i, false)
    end
    if (l%4 == 3)
        add_rectangle_helper!(tiling, w, x + 2*div(l,4), y + 4*div(l,4), true)
    end
end

function add_up_trapezoid!(tiling::TriTiling, l::Int64, w::Int64)
end

function add_down_trapezoid!(tiling::TriTiling, l::Int64, w::Int64)
end
