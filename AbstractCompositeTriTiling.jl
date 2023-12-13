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
include("GenericTriTiling.jl")
include("PeriodicTriTiling.jl")

abstract type AbstractCompositeTriTiling <: TriTiling end

@kwdef mutable struct CompositeTriTiling <: AbstractCompositeTriTiling
    up_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    down_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    iterate::Function = composite_iterator
    get_up::Function = generic_get_up
    get_down::Function = generic_get_down
    set_up!::Function = generic_set_up!
    set_down!::Function = generic_set_down!
    iterator_helper_array::Vector{Vector{Tuple{Int64, Int64}}} = [[(1,1)]]
    domain_dimensions::Vector{Int64} = [1,1]
    composite_domains::Vector{Tuple{Any,Any}} = []
end

@kwdef mutable struct PeriodicCompositeTriTiling <: AbstractCompositeTriTiling
    up_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    down_configs::Vector{Vector{Int64}} = [[Int64(1)]]
    iterate::Function = periodic_iterator
    get_up::Function = periodic_get_up
    get_down::Function = periodic_get_down
    set_up!::Function = periodic_set_up!
    set_down!::Function = periodic_set_down!
    shift::Tuple{Int64, Int64} = (0,0)
    iterator_helper_array::Vector{Vector{Tuple{Int64, Int64}}} = [[]]
    domain_dimensions::Vector{Int64} = [1,1]
    composite_domains::Vector{Tuple{Any,Any}} = []
end

#shift = (y, x) how much the coor shifts when the other one overfills


function add_to_iterator_helper!(tiling::CompositeTriTiling, x::Int64, y::Int64)
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

function add_to_iterator_helper!(tiling::PeriodicCompositeTriTiling, x::Int64, y::Int64)
    push!(tiling.iterator_helper_array[1], (x,y))
end

function convert_temporary_configurations!(tiling::AbstractCompositeTriTiling)
    l,w = tiling.domain_dimensions
    for x in 1:w for y in 1:l
        add_to_iterator = false
        if tiling.get_up(tiling, x, y) < 56
            tiling.set_up!(tiling, x, y, -1)
        elseif !((tiling.get_up(tiling, x, y) & 7) in [0,1,2,4])
            throw(ArgumentError("Domains cannot be merged--one vertex ends up matched to multiple vertices"))
        else
            add_to_iterator = true
            tiling.set_up!(tiling, x, y, 7 & tiling.get_up(tiling, x, y))
            if tiling.get_up(tiling, x, y) == 4
                tiling.set_up!(tiling, x, y, 3)
            end
        end
        if tiling.get_down(tiling, x,y) < 56
            tiling.set_down!(tiling, x, y, -1)
        elseif !((tiling.get_down(tiling, x, y) & 7) in [0,1,2,4])
            throw(ArgumentError("Domains cannot be merged--one vertex ends up matched to multiple vertices"))
        else
            add_to_iterator = true
            tiling.set_down!(tiling, x,y, 7 & tiling.get_down(tiling, x, y))
            if tiling.get_down(tiling,x,y) == 4
                tiling.set_down!(tiling, x, y, 3)
            end
        end
        if add_to_iterator
            add_to_iterator_helper!(tiling, x, y)
        end
    end
    end
end

function composite_initalizer!(tiling::AbstractCompositeTriTiling)
    #We will assume domain_dimensions, composite_domains have been set
    l,w = tiling.domain_dimensions
    if typeof(tiling) == CompositeTriTiling
        tiling.iterator_helper_array = [[] for _ in 1:16]
    end
    tiling.up_configs = [[0 for _ in 1:l] for _ in 1:w]
    tiling.down_configs = [[0 for _ in 1:l] for _ in 1:w]
    for (add_domain, inputs) in tiling.composite_domains
        add_domain(tiling, inputs...)
    end
    convert_temporary_configurations!(tiling)
end

function composite_iterator(tiling::CompositeTriTiling, update_type::Function; axis::Int64 = 1, color::Int64 = 0, is_up::Bool = true)
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

function periodic_iterator(tiling::PeriodicCompositeTriTiling, update_type::Function; axis::Int64 = 1, color::Int64 = 0, is_up::Bool = true)
    if update_type == update_triangle!
        for (x,y) in tiling.iterator_helper_array[1]
            update_type(tiling, x, y, is_up)
        end
    elseif update_type == update_lozenge! || update_type == update_butterfly!
        for (x,y) in tiling.iterator_helper_array[1]
            update_type(tiling, x, y, axis)
        end
    end
end
