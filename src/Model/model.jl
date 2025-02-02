using Printf

task_times = Dict(
    "list.txt" => 1.11,  
    "list1.txt" => 3.18, 
    "list2.txt" => 5.12, 
    "list3.txt" => 6.30, 
    "list4.txt" => 7.29, 
    "list5.txt" => 8.17, 
    "list6.txt" => 8.88, 
    "list7.txt" => 9.56, 
    "list8.txt" => 10.26, 
    "list9.txt" => 10.58, 
    "list10.txt" => 11.05,
    "list11.txt" => 11.71,
    "list12.txt" => 12.19,
    "list13.txt" => 12.61,
    "list14.txt" => 13.02,
    "list15.txt" => 13.46,
    "list16.txt" => 13.94,
    "list17.txt" => 14.29,
    "list18.txt" => 14.60,
    "list19.txt" => 14.97,
    "list20.txt" => 15.23,
    "compile" => 0.09  
)

function calculate_execution_time(task_times::Dict{String, Float64}, num_machines::Int, max_time::Bool)
    compile_time = task_times["compile"]
    list_txt_time = task_times["list.txt"]
    parallel_task_times = [task_times["list$i.txt"] for i in 1:20]

    if max_time
        total_time = sum(parallel_task_times[1:19]) + compile_time + list_txt_time
        max_task_time = parallel_task_times[20]
        return (total_time / num_machines) + max_task_time
    else
        q, r = divrem(20, num_machines)
        parallel_time = sum(parallel_task_times[k * num_machines + r + 1] for k in 0:q if k * num_machines + r < 20)
        return compile_time + parallel_time + list_txt_time
    end
end

function main()
    num_machines_range = 1:20  
    seq_time = calculate_execution_time(task_times, 1, true)

    open("model-performance.txt", "w") do file
        for num_machines in num_machines_range
            exec_time = calculate_execution_time(task_times, num_machines, false)
            acceleration =  seq_time / exec_time
            efficiency = acceleration / num_machines
            println(file, "Machines: $num_machines, Execution: $exec_time, Acceleration: $acceleration, Efficiency: $efficiency")
        end
    end

    open("max-model-results.txt", "w") do file
        for num_machines in num_machines_range
            exec_time = calculate_execution_time(task_times, num_machines, true)
            acceleration = seq_time / exec_time
            efficiency = acceleration / num_machines
            println(file, "Machines: $num_machines, Execution: $exec_time, Acceleration: $acceleration, Efficiency: $efficiency")
        end
    end
end

main()