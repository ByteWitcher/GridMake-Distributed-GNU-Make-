module TaskModule

using Distributed

export MyTask, execute

mutable struct MyTask
    taskName::String
    commands::Vector{String}
    status::String
    isFile::Bool

    function MyTask(taskName::String, commands::Vector{String}, status::String, isFile::Bool)
        new(taskName, commands, status, isFile)
    end
end

# Functions
function execute(task::MyTask)
    try
        for command in task.commands
            println("Executing command: ", command, " ******* for task: ", task.taskName)
            run(`sh -c $command`)
        end
        println("Target completed: ", task.taskName)
    catch e
        println("Error: ", e)
    end
end

end