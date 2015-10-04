
@doc """
`LoaderError` should be thrown when loader library code fails, and other libraries should
be given the chance to recover from the error.  Reports the library name and an error message:
LoaderError("ImageMagick", "Foo not available")
""" ->
immutable LoaderError <: Exception
    library::UTF8String
    msg::UTF8String
end
Base.showerror(io::IO, e::LoaderError) = println(io, e.library, " load error: ",
                                                 msg, "\n  Will try next loader.")

@doc """
`WriterError` should be thrown when writer library code fails, and other libraries should
be given the chance to recover from the error.  Reports the library name and an error message:
WriterError("ImageMagick", "Foo not available")
""" ->
immutable WriterError <: Exception
    library::UTF8String
    msg::UTF8String
end
Base.showerror(io::IO, e::WriterError) = println(
    io, e.library, " writer error: ",
    msg, "\n  Will try next writer."
)


@doc """
`NotInstalledError` should be thrown when a library is currently not installed.
""" ->
immutable NotInstalledError <: Exception
    library::Symbol
    message::UTF8String
end
Base.showerror(io::IO, e::NotInstalledError) = println(io, e.library, " is not installed.")

@doc """
Handles error as soon as they get thrown while doing IO
""" ->
function handle_current_error(e, islast)
    bt = catch_backtrace()
    bts = sprint(io->Base.show_backtrace(io, bt))
    message = islast ? "" : "\nTrying next loading library! Please report this issue on Github"
    warn(string(e, bts, message))
end
handle_current_error(e::NotInstalledError) = warn(string("lib ", e.library, " not installed, trying next library"))

@doc """
Handles a list of thrown errors after no IO library was found working
""" ->
function handle_error(exceptions::Vector)
    for exception in exceptions
        continue_ = handle_error(exception...)
        continue_ || break
    end
end

handle_error(e::NotInstalledError, q) = rethrow(e)

function handle_error(e::NotInstalledError, q)
    println("Library ", e.library, " is not installed but can load format: ", q)
    println("should we install ", e.library, " for you? (y/n):")
    input = chomp(strip(readline(STDIN)))
    if input == "y"
        info("Start installing ", e.library, "...")
        Pkg.add(string(e.library))
        return false # don't continue
    end
    true # User does not install, continue going through errors. 
end


