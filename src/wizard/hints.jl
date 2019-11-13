"""
    print_autoconf_hint(state::WizardState)

Print a hint for projets that use autoconf to have a good `./configure` line.
"""
function print_autoconf_hint(state::WizardState)
    println(state.outs, "    The recommended options for GNU Autoconf are:")
    println(state.outs)
    printstyled(state.outs, "      ./configure --prefix=\${prefix} --build=\${MACHTYPE} --host=\${target}", bold=true)
    println(state.outs)
    println(state.outs)
    println(state.outs, "    followed by `make` and `make install`. Since the prefix environment")
    println(state.outs, "    variable is set already, this will automatically perform the installation")
    println(state.outs, "    into the correct directory.")
end

"""
    provide_hints(state::WizardState, path::AbstractString)

Given an unpacked source directory, provide hints on how a user might go about
building the binary bounty they so richly desire.
"""
function provide_hints(state::WizardState, path::AbstractString)
    files = readdir(path)
    println(state.outs, "You have the following contents in your working directory:")
    println(state.outs, join(map(x->string("  - ", x),files),'\n'))
    printed = false
    function start_hints()
        printed || printstyled(state.outs, "Hints:\n", color=:yellow)
        printed = true
    end
    # Avoid providing duplicate hints (even for files in separate directories)
    # As long as the hint is the same, people will get the idea
    hints_provided = Set{Symbol}()
    function already_hinted(sym)
        start_hints()
        (sym in hints_provided) && return true
        push!(hints_provided, sym)
        return false
    end
    for (root, dirs, files) in walkdir(path)
        for file in files
            file_path = joinpath(root, file)

            # Helper function to try to read the given path's contents, but
            # returning an empty string on error (for e.g. broken symlinks)
            read_contents(path) = try
                String(read(path))
            catch
                ""
            end

            if file == "configure" && occursin("Generated by GNU Autoconf", read_contents(file_path))
                already_hinted(:autoconf) && continue
                println(state.outs, "  - ", replace(file_path, "$path/" => ""), "\n")
                println(state.outs, "    This file is a configure file generated by GNU Autoconf. ")
                print_autoconf_hint(state)
            elseif file == "configure.in" || file == "configure.ac"
                already_hinted(:autoconf) && continue
                println(state.outs, "  - ", replace(file_path, "$path/" => ""), "\n")
                println(state.outs, "    This file is likely input to GNU Autoconf. ")
                print_autoconf_hint(state)
            elseif file == "CMakeLists.txt"
                already_hinted(:CMake) && continue
                println(state.outs, "  - ", replace(file_path, "$path/" => ""), "\n")
                print(state.outs,   "    This file is likely input to CMake. ")
                println(state.outs,   "The recommended options for CMake are")
                println(state.outs)
                printstyled(state.outs, "      cmake -DCMAKE_INSTALL_PREFIX=\$prefix -DCMAKE_TOOLCHAIN_FILE=\${CMAKE_TARGET_TOOLCHAIN}", bold=true)
                println(state.outs)
                println(state.outs)
                println(state.outs, "    followed by `make` and `make install`. Since the prefix environment")
                println(state.outs, "    variable is set already, this will automatically perform the installation")
                println(state.outs, "    into the correct directory.\n")
            elseif file == "meson.build"
                already_hinted(:Meson) && continue
                println(state.outs, "  - ", replace(file_path, "$path/" => ""), "\n")
                print(state.outs,   "    This file is likely input to Meson. ")
                println(state.outs,   "The recommended option for Meson is")
                println(state.outs)
                printstyled(state.outs, "      meson --cross-file=\${MESON_TARGET_TOOLCHAIN}", bold=true)
                println(state.outs)
                println(state.outs)
                println(state.outs, "    followed by `ninja` and `ninja install`. Since the prefix variable")
                println(state.outs, "    is set already, this will automatically perform the installation")
                println(state.outs, "    into the correct directory.\n")
            end
        end
    end
    println(state.outs)
end
