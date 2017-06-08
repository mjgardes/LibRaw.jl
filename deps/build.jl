using BinDeps

@BinDeps.setup

libraw = library_dependency("libraw")
provides(Sources,
         URI("https://www.libraw.org/data/LibRaw-0.18.2.tar.gz"),
         libraw, unpacked_dir="LibRaw-0.18.2")
options = ["--enable-static=no", "--enable-shared=yes", "--disable-fortran"]
autotools = Autotools(libtarget="lib/libraw.la", configure_options=options)
provides(BuildProcess, autotools, libraw)

#@static if is_apple()
#    using Homebrew
#    provides(Homebrew.HB, "libraw", libraw, os = :Darwin )
#end

@BinDeps.install Dict(:libraw => :libraw)
