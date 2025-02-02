using Distributed
# using PyPlot

include(joinpath(ENV["HOME"], "src/Launcher/launcher.jl"))
using .LauncherModule
include(joinpath(ENV["HOME"], "src/Nodes/master.jl"))
using .MasterModule

struct Metric
    machines_count::Int
    execution_time::Float64
    acceleration::Float64
    efficiency::Float64
end

metrics = Metric[]

machines_count = 2:20


function measure_parallel_time(n)
    file_path = joinpath(ENV["HOME"], "makefiles/premier/Makefile")

    targets = parse_makefile(file_path)
    graph = build_dependency_graph(targets)

    println("Measuring parallel time ($n machines)...")

    free_worker_hosts = []

    for worker in workers()[1:n]
        push!(free_worker_hosts, worker)
    end

    tasksExecutionTime = @elapsed begin
        execute_tasks(graph, free_worker_hosts)
    end
    println("Parallel task execution time with $n machines: $tasksExecutionTime seconds")

    # Clean up files after execution
    println("Cleaning up generated files...")
    run(`sh -c 'rm -f list*'`)  # Remove files starting with 'list'
    run(`sh -c 'rm -f premier'`)  # Remove the 'premier' file
    println("Cleanup complete for $n machines.")

    return tasksExecutionTime
end

function calculate_acceleration()
    println("Getting worker hosts...")
    worker_hosts = get_worker_hosts()
    println("Worker hosts: ", worker_hosts)
    addprocs([(worker_host, 1) for worker_host in worker_hosts], exename="/opt/julia-1.9.4/bin/julia")

    @everywhere include(joinpath(ENV["HOME"], "src/Launcher/launcher.jl"))
    @everywhere include(joinpath(ENV["HOME"], "src/Tasks/task.jl"))  

    T_sequential = measure_parallel_time(1)
    println("Execution time with 1 machine : $T_sequential")
    println("Acceleration with 1 machine: 1")
    println("Efficiency with 1 machine: 1")
    push!(metrics, Metric(1, T_sequential, 1, 1))

    # machines = []
    # accelerations = []
    # efficiencies = []

    for n in machines_count
        T_parallel = measure_parallel_time(n)
        acceleration = T_sequential / T_parallel
        efficiency = T_sequential / (n * T_parallel)
        # push!(machines, n)
        # push!(accelerations, acceleration)
        # push!(efficiencies, efficiency)
        println("Execution time with $n machines : $T_parallel")
        println("Acceleration with $n machines: $acceleration")
        println("Efficiency with $n machines: $efficiency")
        push!(metrics, Metric(n, T_parallel, acceleration, efficiency))
    end

    # Write metrics to a file
    println("Writing metrics to file...")
    open("make-performance-results.txt", "w") do f
        for m in metrics
            println(f, "Machines: $(m.machines_count), Execution: $(m.execution_time), Acceleration: $(m.acceleration), Efficiency: $(m.efficiency)")
        end
    end
    println("Metrics written to file")

    # figure()
    # plot(machines, accelerations, marker="o", label="Acceleration", linewidth=2)
    # xlabel("Number of Machines")
    # ylabel("Acceleration")
    # title("Acceleration vs. Number of Machines")
    # legend()
    # grid(true)
    # savefig("acceleration_plot.png")
    # println("Plots generated successfully!")
end

@time calculate_acceleration()