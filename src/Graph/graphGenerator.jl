module GraphGeneratorModule


include(joinpath(ENV["HOME"], "src/Tasks/task.jl"))
include(joinpath(ENV["HOME"], "src/Parser/makefileParser.jl"))

using .TaskModule: MyTask,execute
using .MakefileParserModule

export MyTask,Target,build_dependency_graph,execute,parse_makefile

# Function to generate graph of dependencies
function build_dependency_graph(targets::Dict{String, Target})
    graph = Dict{MyTask, Vector{MyTask}}()

    # Dict to search if a dependency is a task or not
    task_lookup = Dict{String, MyTask}()
    for (name, target) in targets
        task_lookup[name] = MyTask(target.name, target.commands, "NOT_STARTED", true)
    end

    # For each target search for its dependencies, and insert them as tasks
    for (name, target) in targets
        current_task = task_lookup[name]
        dependencies = Vector{MyTask}()

        for dependency_name in target.dependencies
            if haskey(task_lookup, dependency_name)
                push!(dependencies, task_lookup[dependency_name])
            end
        end

        graph[current_task] = dependencies
    end

    return graph
end

end