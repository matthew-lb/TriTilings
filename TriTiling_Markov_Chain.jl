#################### TILING IMPLEMENTATION ####################
include("TriTilings.jl")

function rotate_upface_clockwise!(tiling::TriTiling, x::Int64, y::Int64)
    if tiling.get_up(tiling, x, y) == 1 #Orientation \ -> _
        #Adjust center, then right, then below
        tiling.set_up!(tiling, x,y,2)
        tiling.set_down!(tiling,x,y,0)
        tiling.set_down!(tiling,x,y+1,2)
    elseif tiling.get_up(tiling, x, y) == 2 #Orienation _-> /
        #Adjust center, then below, then left
        tiling.set_up!(tiling, x,y,3)
        tiling.set_down!(tiling,x,y+1,0)
        tiling.set_down!(tiling,x-1,y,3)
    elseif tiling.get_up(tiling, x, y) == 3 #Orientation / -> \
        #Adjust center, then left, then right
        tiling.set_up!(tiling, x,y,1)
        tiling.set_down!(tiling,x-1,y,0)
        tiling.set_down!(tiling,x,y,1)
    end
end

function rotate_downface_clockwise!(tiling::TriTiling, x::Int64, y::Int64)
    if tiling.get_down(tiling, x, y) == 1 #Orientation \ -> _
        #Adjust center, then left, then up
        tiling.set_down!(tiling,x,y,2)
        tiling.set_up!(tiling,x,y,0)
        tiling.set_up!(tiling,x,y-1,2)
    elseif tiling.get_down(tiling, x, y) == 2 #Orientation _ -> /
        #Adjust center, then up, then right
        tiling.set_down!(tiling,x,y,3)
        tiling.set_up!(tiling,x,y-1,0)
        tiling.set_up!(tiling,x+1,y,3)
    elseif tiling.get_down(tiling, x, y) == 3 #Orientation / -> \
        #Adjust center, then right, then left
        tiling.set_down!(tiling,x,y,1)
        tiling.set_up!(tiling,x+1,y,0)
        tiling.set_up!(tiling,x,y,1)
    end
end

function rotate_upface_anticlockwise!(tiling::TriTiling, x::Int64, y::Int64)
    if tiling.get_up(tiling, x, y) == 1
        tiling.set_up!(tiling, x, y, 3)
        tiling.set_down!(tiling, x, y, 0)
        tiling.set_down!(tiling, x - 1, y, 3)
    elseif tiling.get_up(tiling, x, y) == 2
        tiling.set_up!(tiling, x, y, 1)
        tiling.set_down!(tiling, x, y+1, 0)
        tiling.set_down!(tiling, x, y, 1)
    elseif tiling.get_up(tiling, x, y) == 3
        tiling.set_up!(tiling, x, y, 2)
        tiling.set_down!(tiling, x-1, y, 0)
        tiling.set_down!(tiling, x, y+1, 2)
    end
end

function rotate_downface_anticlockwise!(tiling::TriTiling, x::Int64, y::Int64)
    if tiling.get_down(tiling, x, y) == 1
        tiling.set_down!(tiling, x, y, 3)
        tiling.set_up!(tiling, x, y, 0)
        tiling.set_up!(tiling, x + 1, y, 3)
    elseif tiling.get_down(tiling, x, y) == 2
        tiling.set_down!(tiling, x, y, 1)
        tiling.set_up!(tiling, x, y-1, 0)
        tiling.set_up!(tiling, x, y, 1)
    elseif tiling.get_down(tiling, x, y) == 3
        tiling.set_down!(tiling, x, y, 2)
        tiling.set_up!(tiling, x+1, y, 0)
        tiling.set_up!(tiling, x, y-1, 2)
    end
end

function rotate_face!(tiling::TriTiling, x::Int64, y::Int64, is_up::Bool, clkwise::Bool)
    if is_up && clkwise
        rotate_upface_clockwise!(tiling,x,y)
    elseif is_up
        rotate_upface_anticlockwise!(tiling,x,y)
    elseif clkwise
        rotate_downface_clockwise!(tiling,x,y)
    else
        rotate_downface_anticlockwise!(tiling,x,y)
    end
end

function update_lozenge!(tiling::TriTiling, x::Int64, y::Int64, axis::Int64)
    #Position of lozenge is defined by the coordinate of the up face
    #NOTE: Make sure this is only called when all relevant faces > 0
    if axis == 1
        if (tiling.get_up(tiling,x,y) != 1) && (tiling.get_up(tiling,x,y) == tiling.get_down(tiling,x,y))
            clkwise = (tiling.get_up(tiling,x,y) == 2)
            rotate_face!(tiling, x, y, true, clkwise)
            rotate_face!(tiling, x, y, false, clkwise)  
        end
    elseif axis == 2
        if (tiling.get_up(tiling,x,y) != 2) && (tiling.get_up(tiling,x,y) == tiling.get_down(tiling,x,y+1))
            clkwise = (tiling.get_up(tiling,x,y) == 3)
            rotate_face!(tiling, x, y, true, clkwise)
            rotate_face!(tiling, x, y+1, false, clkwise) 
        end
    elseif axis == 3
        if (tiling.get_up(tiling,x,y) != 3) && (tiling.get_up(tiling,x,y) == tiling.get_down(tiling,x-1,y))
            clkwise = (tiling.get_up(tiling,x,y) == 1)
            rotate_face!(tiling, x, y, true, clkwise)
            rotate_face!(tiling, x-1, y, false, clkwise) 
        end
    end
end

function is_triangle(tiling::TriTiling, x::Int64, y::Int64, is_up::Bool)
    if is_up
        return (tiling.get_down(tiling,x,y) == 0) && (tiling.get_up(tiling,x,y) > 0) && (tiling.get_up(tiling,x+1,y) > 0) && (tiling.get_up(tiling,x,y-1) > 0)
    else
        return (tiling.get_up(tiling,x,y) == 0) && (tiling.get_down(tiling,x-1,y) > 0) && (tiling.get_down(tiling,x,y) > 0) && (tiling.get_down(tiling,x,y+1) > 0)
    end 
end

function update_triangle!(tiling::TriTiling, x::Int64, y::Int64, is_up::Bool)
    if is_triangle(tiling, x, y, is_up)
        if is_up
            clkwise = (tiling.get_up(tiling,x,y) == 2)
            rotate_face!(tiling, x, y, true, clkwise)
            rotate_face!(tiling, x+1, y, true, clkwise)
            rotate_face!(tiling, x, y-1, true, clkwise)
        else
            clkwise = (tiling.get_down(tiling,x-1,y) == 1)
            rotate_face!(tiling, x-1, y, false, clkwise)
            rotate_face!(tiling, x, y, false, clkwise)
            rotate_face!(tiling, x, y+1, false, clkwise)       
        end
    end
end

function is_butterfly(tiling::TriTiling, x::Int64, y::Int64, axis::Int64)
    if axis == 1
        return (tiling.get_up(tiling,x,y) == 0) && (tiling.get_down(tiling,x,y) == 0) && (tiling.get_down(tiling,x-1,y) > 0) && (tiling.get_up(tiling,x,y-1) > 0) && (tiling.get_up(tiling,x+1,y) > 0) && (tiling.get_down(tiling,x,y+1) > 0)
    elseif axis == 2
        return (tiling.get_up(tiling,x,y) == 0) && (tiling.get_down(tiling,x,y+1) == 0) && (tiling.get_down(tiling,x-1,y) > 0) && (tiling.get_up(tiling,x,y+1) > 0) && (tiling.get_down(tiling,x,y) > 0) && (tiling.get_up(tiling,x+1,y+1) > 0)
    elseif axis == 3
        return (tiling.get_up(tiling,x,y) == 0) && (tiling.get_down(tiling,x-1,y) == 0) && (tiling.get_up(tiling,x-1,y-1) > 0) && (tiling.get_up(tiling,x-1,y) > 0) && (tiling.get_down(tiling,x,y+1) > 0) && (tiling.get_down(tiling,x,y) > 0)
    end
end

function update_butterfly!(tiling::TriTiling, x::Int64, y::Int64, axis::Int64)
    if is_butterfly(tiling, x, y, axis)
        if axis == 1
            clkwise = (tiling.get_down(tiling,x-1,y) == 1)
            rotate_face!(tiling, x-1, y, false, clkwise)
            rotate_face!(tiling, x, y+1, false, clkwise)
            rotate_face!(tiling, x, y-1, true, clkwise)
            rotate_face!(tiling, x+1, y, true, clkwise)
        elseif axis == 2
            clkwise = (tiling.get_down(tiling,x,y) == 2)
            rotate_face!(tiling, x-1, y, false, clkwise)
            rotate_face!(tiling, x, y+1, true, clkwise)
            rotate_face!(tiling, x, y, false, clkwise)
            rotate_face!(tiling, x+1, y+1, true, clkwise)
        elseif axis == 3
            clkwise = (tiling.get_down(tiling,x,y) == 2)
            rotate_face!(tiling, x, y, false, clkwise)
            rotate_face!(tiling, x, y+1, false, clkwise)
            rotate_face!(tiling, x-1, y, true, clkwise)
            rotate_face!(tiling, x-1, y-1, true, clkwise)
        end
    end
end

function random_update!(tiling::TriTiling)
    axis = Int64(rand(1:3))
    bicolor = Int64(rand(0:1))
    tricolor = Int64(rand(0:2))
    move = rand(0:2)    
    if move == 0
        tiling.iterate(tiling, update_lozenge!, axis = axis, color = bicolor)
    elseif move == 1
        tiling.iterate(tiling, update_triangle!, axis = axis, color = bicolor, is_up = (bicolor == 0))
    else
        tiling.iterate(tiling, update_butterfly!, axis = axis, color = tricolor)
    end
end

function systematic_update!(tiling::TriTiling, lozenge_count = 4, triangle_count = 1, butterfly_count = 1)
    for _ in lozenge_count
        for axis in 1:3
            for bicolor in 0:1
                tiling.iterate(tiling, update_lozenge!, axis = axis, color = bicolor)
            end
        end
    end
    for _ in triangle_count
        for up in 0:1
            tiling.iterate(tiling, update_triangle!, axis  = 1, color = 1, is_up = (up == 0))
        end
    end
    for _ in butterfly_count
        for axis in 1:3
            for tricolor in 0:2
                tiling.iterate(tiling, update_butterfly!, axis = axis, color = tricolor)
            end
        end
    end
end
