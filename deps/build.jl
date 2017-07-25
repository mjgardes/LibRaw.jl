using BinDeps

@BinDeps.setup

libraw = library_dependency("libraw")
provides(Sources,
         URI("https://www.libraw.org/data/LibRaw-0.18.2.tar.gz"),
         libraw, unpacked_dir="LibRaw-0.18.2")
options = ["--enable-static=no", "--enable-shared=yes", "--disable-fortran"]
autotools = Autotools(libtarget="lib/libraw.la", configure_options=options)
provides(BuildProcess, autotools, libraw)

libraw_interface = library_dependency("libraw_interface")
prefix=joinpath(Pkg.dir(), "deps", "usr")
srcdir = joinpath(Pkg.dir("LibRaw"), "deps", "interface")
builddir = joinpath(Pkg.dir(), "deps", "builds", "libraw_interface")
provides(BuildProcess,
    (@build_steps begin
        CreateDirectory(builddir)
        @build_steps begin
            ChangeDirectory(builddir)
            FileRule([joinpath(prefix, "lib", "libraw_interface.so"),
                      joinpath(prefix, "lib", "libraw_interface.dylib")],
                     @build_steps begin
                `cmake -DCMAKE_INSTALL_PREFIX="$prefix" $srcdir -DCMAKE_PREFIX_PATH="$prefix"`
                `cmake --build . --target install`
            end)
        end
    end), libraw_interface)

@BinDeps.install Dict(:libraw => :libraw, :libraw_interface => :libraw_interface)
