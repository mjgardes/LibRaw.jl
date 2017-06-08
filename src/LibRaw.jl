module LibRaw
using AxisArrays
using Cxx

export LibRawImage, libraw_version

if isfile(joinpath(Pkg.dir("LibRaw"),"deps","deps.jl"))
    include(joinpath(Pkg.dir("LibRaw"),"deps","deps.jl"))
else
    error("LibRaw not properly installed. Please run Pkg.build(\"LibRaw\")")
end

const headerdir = joinpath(dirname(dirname(libraw)), "include", "libraw")
Cxx.addHeaderDir(headerdir, kind=Cxx.C_User)
Cxx.cxxinclude("libraw.h")
Libdl.dlopen(libraw, Libdl.RTLD_GLOBAL)

const libraw_version = let v=@cxx LibRaw::version()
    VersionNumber(unsafe_string(v))
end

# const supported_cameras = let n = @cxx LibRaw::cameraCount(), strings = @
#     n = 

type LibRawImage
    filename::String
    ptr::Ptr{Void}
    isunpacked::Bool
end

LibRawImage(path::String; open=true) = begin
    ptr = @cxxnew LibRaw()
    result = LibRawImage(path, ptr, false)
    if open
        err = @cxx ptr->open_file(Base.unsafe_convert(Ptr{UInt8}, path))
        err ≠ 0 && error("Got error code $err when opening file $path")
    end
    result
end

cxx"""
char const * _c_make(void *x) { return ((LibRaw*)x)->imgdata.idata.make; }
char const * _c_model(void *x) { return ((LibRaw*)x)->imgdata.idata.model; }
char const * _c_cdesc(void *x) { return ((LibRaw*)x)->imgdata.idata.cdesc; }
int64_t _c_raw_width(void *x) { return ((LibRaw*)x)->imgdata.sizes.raw_width; }
int64_t _c_raw_height(void *x) { return ((LibRaw*)x)->imgdata.sizes.raw_height; }
int64_t _c_width(void *x) { return ((LibRaw*)x)->imgdata.sizes.width; }
int64_t _c_height(void *x) { return ((LibRaw*)x)->imgdata.sizes.height; }
int64_t _c_iwidth(void *x) { return ((LibRaw*)x)->imgdata.sizes.iwidth; }
int64_t _c_iheight(void *x) { return ((LibRaw*)x)->imgdata.sizes.iheight; }
double _c_iso_speed(void *x) { return ((LibRaw*)x)->imgdata.other.iso_speed; }
double _c_shutter(void *x) { return ((LibRaw*)x)->imgdata.other.shutter; }
double _c_aperture(void *x) { return ((LibRaw*)x)->imgdata.other.aperture; }
double _c_focal_length(void *x) { return ((LibRaw*)x)->imgdata.other.focal_len; }
int _c_unpack(void *x) { return ((LibRaw*)x)->unpack(); }
int _c_raw2image(void *x) { return ((LibRaw*)x)->raw2image(); }
unsigned short* _c_image(void *x) { return &(((LibRaw*)x)->imgdata.image[0][0]); }
"""

""" Make of the camera """
make(x::LibRawImage) = unsafe_string(@cxx _c_make(x.ptr))
""" Model of the camera """
model(x::LibRawImage) = unsafe_string(@cxx _c_model(x.ptr))
""" Description of the Bayer mosaic """
color_description(x::LibRawImage) = unsafe_string(@cxx _c_cdesc(x.ptr))
raw_size(x::LibRawImage) = (@cxx _c_raw_width(x.ptr)), (@cxx _c_raw_height(x.ptr))
Base.size(x::LibRawImage) = (@cxx _c_width(x.ptr)), (@cxx _c_height(x.ptr))
output_size(x::LibRawImage) = (@cxx _c_iwidth(x.ptr)), (@cxx _c_iheight(x.ptr))
iso_speed(x::LibRawImage) = (@cxx _c_iso_speed(x.ptr))
shutter_speed(x::LibRawImage) = @cxx _c_shutter(x.ptr)
aperture(x::LibRawImage) = (@cxx _c_aperture(x.ptr))
focal_length(x::LibRawImage) = (@cxx _c_focal_length(x.ptr))

image_data(x::LibRawImage) = begin
    width, height = output_size(x)

    if !x.isunpacked
        err = @cxx _c_unpack(x.ptr)
        err == 0 || err("Error code $error recovered while unpacking image")
        x.isunpacked = true
    end
    err = @cxx _c_raw2image(x.ptr)
    err == 0 || err("Error code $error recovered while unpacking image")

    raw = @cxx _c_image(x.ptr)
    raw == C_NULL && error("Could not recover image data")
    result = unsafe_wrap(Array{Cushort, 3}, raw, (4, width, height))

    cdesc = color_description(x)
    name(input) = begin
        i, x = input
        n = count(j -> j == x, cdesc[1:i-1])
        n == 0 ? Symbol(x): Symbol(string(x) * string(n + 1))
    end
    axis = map(name, enumerate(cdesc))
    AxisArray(permutedims(result, [3, 2, 1]),
              Axis{:h}(1:size(result, 3)), Axis{:v}(1:size(result, 2)), Axis{:color}(axis))
end


end # module
