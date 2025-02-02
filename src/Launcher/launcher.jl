module LauncherModule

using Distributed

include(joinpath(ENV["HOME"], "src/Graph/graphGenerator.jl"))

using .GraphGeneratorModule

export execute_tasks, all_tasks_completed, can_be_executed, build_dependency_graph, parse_makefile

# Functions
function execute_tasks(graph::Dict{MyTask, Vector{MyTask}}, free_worker_hosts::Vector{Any})
    @sync begin
        while !all_tasks_completed(graph)
            for task in keys(graph)
                if can_be_executed(task, graph)
                    @async begin
                        if !isempty(free_worker_hosts)
                            worker = pop!(free_worker_hosts)
                            println("Worker $(worker) is occupied for $(task.taskName).")
                            task.status = "IN_PROGRESS"
                            fetch(@spawnat worker execute(task))
                            task.status = "FINISHED"
                            push!(free_worker_hosts, worker)
                            println("Worker $(worker) is free.")
                            # Remove the task from the graph after completion
                            delete!(graph, task)
                        # else
                        #     # println("No free workers available; task $(task.taskName) waiting.")
                        #     sleep(0.1)
                        end
                    end
                # else
                #     println("Task $(task.taskName): $(task.status)")
                end
            end
            sleep(0.5)
        end
    end
end

# Check if all tasks are completed
function all_tasks_completed(graph::Dict{MyTask, Vector{MyTask}})::Bool
    return all(task.status == "FINISHED" for task in keys(graph))
end

# Check if a task can be executed
function can_be_executed(task::MyTask, graph::Dict{MyTask, Vector{MyTask}})::Bool
    if task.status != "NOT_STARTED"
        return false
    end
    dependencies = graph[task]
    return isempty(dependencies) || all(dep.status == "FINISHED" for dep in dependencies) # Here I check the status of dependencies of the task
end

end
