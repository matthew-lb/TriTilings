#=
Implements Several Simple Domains for TriTilings
=#

include("AbstractCompositeTriTiling.jl")

#################### SIMPLE DOMAINS ####################

function set_up_or_equals!(tiling, x, y, value)
    tiling.set_up!(tiling, x, y, value | tiling.get_up(tiling, x, y))
end

function set_down_or_equals!(tiling, x, y, value)
    tiling.set_down!(tiling, x, y, value | tiling.get_down(tiling, x, y))
end

function add_axis_one_line!(tiling::AbstractCompositeTriTiling, l::Int64, x::Int64, y::Int64)
    if l%2 != 1
        throw(DomainError((l,1), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:l
        set_down_or_equals!(tiling, x+i-1, y+i, 16)
        set_up_or_equals!( tiling, x+i, y+i-1,  32)
    end
    for i in 0:(l-1)
        set_up_or_equals!( tiling, x+i, y+i, 24) #8+16
        set_down_or_equals!(tiling, x+i, y+i, 40) #8+32
    end
    set_down_or_equals!(tiling, x-1, y-1, 32)
    set_up_or_equals!(tiling, x-1, y-1, 16)
    set_up_or_equals!(tiling, x+l, y+l, 8)
    set_up_or_equals!(tiling, x+l, y+l, 8)
    #Set 1,2,4 components
    for i in 0:2:(l-1)
        set_up_or_equals!( tiling, x+i, y+i, 1)
        set_down_or_equals!(tiling, x+i, y+i, 1)
    end
end

function add_axis_two_line!(tiling::AbstractCompositeTriTiling, w::Int64, x::Int64, y::Int64)
    #w refers to length not number of points
    if w%2 != 1
        throw(DomainError((1,w), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:w
        set_up_or_equals!( tiling, x+i, y, 8)
        set_down_or_equals!(tiling, x+i-1, y-1, 32)
    end
    for i in 0:(w-1)
        set_down_or_equals!(tiling, x+i, y, 24) #8+16
        set_up_or_equals!( tiling, x+i, y-1, 48) #16+32
    end
    set_up_or_equals!(tiling, x-1, y-1, 16)
    set_down_or_equals!(tiling, x-1, y, 16)
    set_up_or_equals!(tiling, x+w, y-1, 32)
    set_down_or_equals!(tiling, x+w, y, 8)
    #Set 1,2,4 components
    for i in 0:2:(w-1)
        set_up_or_equals!( tiling, x+i, y-1, 2)
        set_down_or_equals!(tiling, x+i, y, 2)
    end
end

function add_axis_three_line!(tiling::AbstractCompositeTriTiling, l::Int64, x::Int64, y::Int64)
    if l%2 != 1
        throw(DomainError((l,1), "No tiling of the domain with such side lengths exists"))
    end
    #Set 16, 32, 64 components
    for i in 0:l
        set_down_or_equals!(tiling, x, y+i, 8)
        set_up_or_equals!( tiling, x-1, y+i-1, 16)
    end
    for i in 0:(l-1)
        set_down_or_equals!(tiling, x-1, y+i, 48) #8+16
        set_up_or_equals!( tiling, x, y+i, 40) #16+32
    end
    set_down_or_equals!(tiling, x-1, y-1, 32)
    set_up_or_equals!(tiling, x, y-1, 32)
    set_up_or_equals!(tiling, x, y+l, 8)
    set_down_or_equals!(tiling, x-1, y+l, 16)
    #Set 1,2,4 components
    for i in 0:2:(l-1)
        set_up_or_equals!( tiling, x, y+i, 4)
        set_down_or_equals!(tiling, x-1, y+i, 4)
    end
end

function add_parallelogram!(tiling::AbstractCompositeTriTiling, l::Int64, w::Int64, x::Int64, y::Int64, axis::Int64)
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

function add_rectangle_helper!(tiling::AbstractCompositeTriTiling, w::Int64, x::Int64, y::Int64, odd = true)
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

function add_rectangle!(tiling::AbstractCompositeTriTiling, l::Int64, w::Int64, x::Int64, y::Int64)
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

function add_up_trapezoid!(tiling::AbstractCompositeTriTiling, l::Int64, w::Int64, x::Int64, y::Int64)
    if (w%2 != 1) || (l%4 != 3 && l%4 != 0)
        throw(DomainError((l,w), "Tiling of the domain either does not exist or has not been implemented"))
    end
    if l % 4 == 0
        add_axis_two_line!(tiling, w + l, x, y + l)
        add_up_trapezoid!(tiling, l - 1, w, x, y)
    else
        add_parallelogram!(tiling, l, w, x, y, 1)
        add_axis_one_line!(tiling, 1, x + w + 1, y + 1)
        add_axis_two_line!(tiling, 1, x + w + 2, y + 3)
        add_axis_three_line!(tiling, 1, x + w + 1, y + 2)
        if l > 3
            add_up_trapezoid!(tiling, l - 4, 3, x + w + 1, y + 4)
        end
    end
end 

function add_down_trapezoid!(tiling::AbstractCompositeTriTiling, l::Int64, w::Int64, x::Int64, y::Int64) #w refers to lower boundary
    if (w%2 != 1) || (l%4 != 3 && l%4 != 0)
        throw(DomainError((l,w), "Tiling of the domain either does not exist or has not been implemented"))
    end
    if l % 4 == 0
        add_axis_two_line!(tiling, w + l, x, y)
        add_down_trapezoid!(tiling, l - 1, w, x+1, y+1)
    else
        add_parallelogram!(tiling, l, w, x+l, y, 1)
        add_axis_one_line!(tiling, 1, x + l - 2, y + l - 2)
        add_axis_two_line!(tiling, 1, x + l - 3, y + l - 3)
        add_axis_three_line!(tiling, 1, x + l - 1, y + l - 3)
        if l > 3
            add_down_trapezoid!(tiling, l - 4, 3, x, y)
        end
    end
end
