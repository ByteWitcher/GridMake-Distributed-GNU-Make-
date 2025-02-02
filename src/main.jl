using Distributed

include(joinpath(ENV["HOME"], "src/Launcher/launcher.jl"))
using .LauncherModule
include(joinpath(ENV["HOME"], "src/Nodes/master.jl"))
using .MasterModule

function main()
    println("Reading the Makefile...")
    # file_path = joinpath(ENV["HOME"], "tests/Makefile")
    # file_path = joinpath(ENV["HOME"], "makefiles/premier/Makefile")
    file_path = joinpath(ENV["HOME"], "Makefile")

    println("Parsing the Makefile...")
    parsingTime = @elapsed begin
        targets = parse_makefile(file_path)
    end
    println("Parsed the file in $(parsingTime)s")

    println("Generating dependencies graph...")
    graphGenerationTime = @elapsed begin
        graph = build_dependency_graph(targets)
    end
    println("Graph generated in $(graphGenerationTime)s")

    free_worker_hosts = []
    println("Getting worker hosts...")
    worker_hosts = get_worker_hosts()
    println("Worker hosts: ", worker_hosts)
    addprocs([(worker_host, 1) for worker_host in worker_hosts], exename="/opt/julia-1.9.4/bin/julia")
    println("Workers: ", workers())
    println("Number of processes: ", nprocs())
    println("Number of worker processes: ", nworkers())
    for worker in workers()
        println(worker)
        push!(free_worker_hosts, worker)
    end

    @everywhere include(joinpath(ENV["HOME"], "src/Launcher/launcher.jl"))
    @everywhere include(joinpath(ENV["HOME"], "src/Tasks/task.jl"))

    println("Executing tasks...")
    tasksExecutionTime = @elapsed begin
        execute_tasks(graph, free_worker_hosts)
    end
    println("It took $(tasksExecutionTime)s to execute all tasks successfully!")
end

@time main()