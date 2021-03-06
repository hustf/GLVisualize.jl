"""
This is the GLViualize Test suite.
It tests all examples in the example folder and has the options to create
docs from the examples.
"""
module GLTest

using GLAbstraction, GLWindow, GLVisualize
using FileIO, GeometryTypes, Reactive
#using GLVisualize.ComposeBackend

const number_of_frames = 360
const interactive_time = 2.0
const screencast_folder = joinpath(homedir(), "glvisualize_screencast")#Pkg.dir("GLVisualizeDocs", "docs", "media")
!isdir(screencast_folder) && mkdir(screencast_folder)

function render_fr(window)
    render_frame(window)
    pollevents()
    swapbuffers(window)
end

function record_test(window, timesignal, nframes=number_of_frames)
    push!(timesignal, 0f0)
    yield()
    render_fr(window) # make sure we start with a valid image
    yield()
    frames = []
    for frame in 1:nframes
        push!(timesignal, frame/nframes)
        render_fr(window)
        push!(frames, screenbuffer(window))
    end
    frames
end
function record_test_static(window)
    yield()
    render_fr(window) # make sure we start with a valid image
    sleep(0.1)
    yield()
    render_fr(window)
    yield()
    render_fr(window)
    return screenbuffer(window)
end
function record_test_interactive(window, timesignal, total_time=interactive_time)
    frames = []
    add_mouse(window)
    push!(timesignal, 0f0)
    for i=1:2 # warm up
        render_fr(window)
        yield()
    end
    start_time = time()
    while time()-start_time < total_time
        push!(timesignal, (start_time-time())/3.0)
        render_fr(window)
        push!(frames, screenbuffer(window))
    end

    frames
end



non_working_list = []


"""
 include the example in it's own module
 to avoid variable conflicts.
 this can be done only via eval.
"""
function include_in_module(name::Symbol, include_path)
    eval(:(
        module $(name)
            using GLTest, Reactive

            const runtests   = true
            const window     = GLTest.window
            const timesignal = Signal(0.0f0)

           # const composebackend = GLTest.composebackend

            include($include_path)
        end
    ))
end
function test_include(path, window)
    try
        println("trying to render $path")
        name = basename(path)[1:end-3] # remove .jl
        # include the example file in it's own module
        test_module = include_in_module(symbol(name), path)
        for (camname, cam) in window.cameras
            # don't center non standard cams
            !in(camname, (:perspective, :orthographic_pixel)) && continue
            center!(cam, renderlist(window))
        end
        # only when something was added to renderlist
        if !isempty(renderlist(window)) || !isempty(window.children)
            if isdefined(test_module, :record_interactive)
                frames = record_test_interactive(window, test_module.timesignal)
            elseif isdefined(test_module, :static_example)
                frames = record_test_static(window)
            else
                frames = record_test(window, test_module.timesignal)
            end
            println("recorded successfully: $name")
            create_video(frames, name, screencast_folder, 1)
        end
    catch e
        println("################################################################")
        bt = catch_backtrace()
        ex = CapturedException(e, bt)
        println("ERROR in $path")
        showerror(STDERR, ex)
        println("\n################################################################")
        push!(non_working_list, path)
    finally
        empty!(window.children)
        empty!(window)
        window.color = RGBA{Float32}(1,1,1,1)
        #empty!(window.cameras)
    end
end

function make_tests(path::AbstractString)
    if isdir(path)
        if basename(path) != "compose" && basename(path) != "gpgpu"
            make_tests(map(x->joinpath(path, x), readdir(path)))
        end
    elseif isfile(path) && endswith(path, ".jl")
        test_include(path, window)
    end
    nothing # ignore other cases
end
function make_tests(directories::Vector)
    for dir in directories
        make_tests(dir)
    end
end

include("mouse.jl")

window = glscreen(resolution=(300, 300))
#composebackend = ComposeBackend.GLVisualizeBackend(window)

const make_docs  = true
srand(777) # set rand seed, to get the same results for tests that use rand

make_tests(Pkg.dir("GLVisualize", "examples"))

isfile("non_working.txt") && rm("non_working.txt")
for elem in non_working_list
    println(elem)
end
open("non_working.txt", "w") do io
    for elem in non_working_list
        println(io, elem)
    end
end

end

using GLTest
