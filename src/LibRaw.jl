module LibRaw
using AxisArrays

export libraw_version, LibRawImage

if isfile(joinpath(Pkg.dir("LibRaw"),"deps","deps.jl"))
    include(joinpath(Pkg.dir("LibRaw"),"deps","deps.jl"))
else
    error("LibRaw not properly installed. Please run Pkg.build(\"LibRaw\")")
end

macro lintpragma(s) end

@lintpragma("Ignore use of undeclared variable ccall")
@lintpragma("Ignore use of undeclared variable libraw")
@lintpragma("Ignore use of undeclared variable libraw_interface")

const libraw_version = let v=ccall((:libraw_version, libraw), Cstring, ())
    VersionNumber(unsafe_string(v))
end

type LibRawImage
    filename::String
    ptr::Ptr{Void}
    isunpacked::Bool
end

Base.close(image::LibRawImage) = begin
    image.ptr == C_NULL && return
    try
        @eval ccall((:libraw_close, $libraw), Void, (Ptr{Void},), $(image.ptr))
    finally
        image.ptr = C_NULL
    end
end

LibRawImage(path::String; open=true) = begin
    ptr = @eval ccall((:libraw_init, $libraw), Ptr{Void}, (Cuint,), 0)
    result = LibRawImage(path, ptr, false)
    finalizer(result, close)
    if open
        err = @eval ccall((:libraw_open_file, $libraw), Cint, (Ptr{Void}, Cstring),
                          $ptr, $path)
        err ≠ 0 && error("Got error code $err when opening file $path")
    end
    result
end

""" Make of the camera """
make(x::LibRawImage) = begin
    result = @eval ccall((:make, $libraw_interface), Cstring, (Ptr{Void}, ), $(x.ptr))
    unsafe_string(result)
end

""" Model of the camera """
model(x::LibRawImage) = begin
    result = @eval ccall((:model, $libraw_interface), Cstring, (Ptr{Void}, ), $(x.ptr))
    unsafe_string(result)
end

""" Description of the Bayer mosaic """
color_description(x::LibRawImage) = begin
    result = @eval ccall((:cdesc, $libraw_interface), Cstring, (Ptr{Void}, ), $(x.ptr))
    unsafe_string(result)
end

raw_size(x::LibRawImage) = begin
    w = @eval ccall((:raw_width, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h = @eval ccall((:raw_height, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h, w
end

Base.size(x::LibRawImage) = begin
    w = @eval ccall((:width, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h = @eval ccall((:height, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h, w
end

output_size(x::LibRawImage) = begin
    w = @eval ccall((:iwidth, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h = @eval ccall((:iheight, $libraw_interface), Int64, (Ptr{Void}, ), $(x.ptr))
    h, w
end

iso_speed(x::LibRawImage) =
    @eval ccall((:iso_speed, $libraw_interface), Cdouble, (Ptr{Void}, ), $(x.ptr))
shutter_speed(x::LibRawImage) =
    @eval ccall((:shutter, $libraw_interface), Cdouble, (Ptr{Void}, ), $(x.ptr))
aperture(x::LibRawImage) =
    @eval ccall((:aperture, $libraw_interface), Cdouble, (Ptr{Void}, ), $(x.ptr))
focal_length(x::LibRawImage) =
    @eval ccall((:focal_length, $libraw_interface), Cdouble, (Ptr{Void}, ), $(x.ptr))
 
image_data(x::LibRawImage) = begin
    height, width = output_size(x)

    if !x.isunpacked
        err = @eval ccall((:libraw_unpack, $libraw), Cint, (Ptr{Void}, ), $(x.ptr))
        err == 0 || err("Error code $error recovered while unpacking image")
        x.isunpacked = true
    end
    err = @eval ccall((:libraw_raw2image, $libraw), Cint, (Ptr{Void}, ), $(x.ptr))
    err == 0 || err("Error code $error recovered while unpacking image")

    raw = @eval ccall((:image, $libraw_interface), Ptr{Cushort}, (Ptr{Void}, ), $(x.ptr))
    raw == C_NULL && error("Could not recover image data")
    result = unsafe_wrap(Array{Cushort, 3}, raw, (4, width, height))

    cdesc = color_description(x)
    name(input) = begin
        i, x = input
        n = count(j -> j == x, cdesc[1:i-1])
        count(j -> j == x, cdesc) == 1 ? Symbol(x): Symbol("$x$(n + 1)")
    end
    axis = map(name, enumerate(cdesc))
    AxisArray(permutedims(result, [3, 2, 1]),
              Axis{:h}(1:size(result, 3)), Axis{:v}(1:size(result, 2)), Axis{:color}(axis))
end


end # module
