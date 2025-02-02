using PyPlot

# Function to read data from file up to a specified maximum size
function read_data(file_path::String, max_size_kb::Int)
    data = []
    pattern = r"Size:\s*(\d+)\s*KB,\s*RTT:\s*([\d\.]+)\s*ms,\s*Throughput:\s*([\d\.]+)\s*Mbytes/s"
    start_reading = false
    start_sentence = "Average metrics by size:"

    open(file_path, "r") do file
        for line in eachline(file)
            # Check if we've found the start sentence
            if occursin(start_sentence, line)
                start_reading = true
                continue
            end
            if start_reading
                match_obj = Base.match(pattern, line)
                if match_obj !== nothing
                    size = parse(Int, match_obj.captures[1])
                    if size > max_size_kb  # Stop reading if size exceeds max_size_kb
                        break
                    end
                    rtt = parse(Float64, match_obj.captures[2])
                    throughput = parse(Float64, match_obj.captures[3])
                    push!(data, (rtt, throughput, size))  # Store rtt, throughput, and size
                end
            end
        end
    end

    return data
end

# Function to plot data (rtt or throughput)
function plot_data(data, save_path::String, plot_type::String)
    if plot_type == "rtt"
        values = [d[1] for d in data]  # Extract latencies
        ylabel = "RTT (ms)"
        color = "tab:red"
    elseif plot_type == "throughput"
        values = [d[2] for d in data]  # Extract throughputs
        ylabel = "Throughput (Mbytes/s)"
        color = "tab:blue"
    else
        println("Invalid plot type: $plot_type. Please choose 'rtt' or 'throughput'.")
        return
    end

    sizes = [d[3] for d in data]  # Extract sizes

    fig, ax1 = subplots()
    ax1.set_xlabel("Size (KB)")
    ax1.set_ylabel(ylabel, color=color)
    
    ax1.plot(sizes, values, color=color, marker="o")
    
    ax1.tick_params(axis="y", labelcolor=color)

    ax1.legend()
    ax1.set_title("$(uppercasefirst(plot_type)) vs Size")
    grid(true)
    
    fig.tight_layout()
    savefig(save_path)
    println("Plot saved as $save_path")
end

# Main function
function main()
    println("Enter the maximum size in KB to read (e.g., 100): ")
    max_size_kb = parse(Int, strip(readline()))

    println("Do you want to run all combinations or a specific combination? ('all' or 'specific')")
    run_choice = string(strip(readline()))

    if run_choice == "all"
        benchmark_types = ["pingpong", "pingpong-io", "nfs", "scp"]
        plot_types = ["rtt", "throughput"]

        # Iterate through all combinations of benchmark type and plot type
        for benchmark_type in benchmark_types
            for plot_type in plot_types
                println("Running for benchmark: $benchmark_type, plot type: $plot_type")

                # Define file paths for benchmark types
                file_paths = Dict(
                    "pingpong" => "src/Scripts/Results/pingpong-results.txt",
                    "pingpong-io" => "src/Scripts/Results/pingpong-io-results.txt",
                    "nfs" => "src/Scripts/Results/nfs-results.txt",
                    "scp" => "src/Scripts/Results/scp-results.txt"
                )

                # Check if the entered benchmark type is valid
                if !haskey(file_paths, benchmark_type)
                    println("Invalid benchmark type '$benchmark_type'. Available types are: $(join(keys(file_paths), ", "))")
                    continue
                end

                file_path = file_paths[benchmark_type]

                data = read_data(file_path, max_size_kb)

                # Define folder structure for saving the plots
                base_dir = "src/Scripts/Results"
                folder_name = ""
                if benchmark_type == "pingpong"
                    folder_name = "PingpongPlots"
                elseif benchmark_type == "pingpong-io"
                    folder_name = "PingpongIoPlots"
                elseif benchmark_type == "nfs"
                    folder_name = "NfsPlots"
                elseif benchmark_type == "scp"
                    folder_name = "ScpPlots"
                end

                # Create the folder if it doesn't exist
                folder_path = joinpath(base_dir, folder_name)
                if !isdir(folder_path)
                    mkdir(folder_path)
                end

                # Set the save path for the plot
                save_path = joinpath(folder_path, "$(benchmark_type)-$(plot_type)-$(max_size_kb)KB.png")

                # Plot the data and save the plot
                plot_data(data, save_path, plot_type)
            end
        end
    elseif run_choice == "specific"
        println("Enter the type of benchmark ('pingpong', 'pingpong-io', 'nfs', 'scp'): ")
        benchmark_type = string(strip(readline()))

         # Define file paths for benchmark types
        file_paths = Dict(
            "pingpong" => "src/Scripts/Results/pingpong-results.txt",
            "pingpong-io" => "src/Scripts/Results/pingpong-io-results.txt",
            "nfs" => "src/Scripts/Results/nfs-results.txt",
            "scp" => "src/Scripts/Results/scp-results.txt"
        )

        # Check if the entered benchmark type is valid
        if !haskey(file_paths, benchmark_type)
            println("Invalid benchmark type '$benchmark_type'. Available types are: $(join(keys(file_paths), ", "))")
            return
        end

        # Ask the user whether to plot rtt or throughput
        println("Do you want to plot 'rtt' or 'throughput'?")
        plot_type = string(strip(readline()))  # Ensure it's a full string

        # Check if the plot type is valid
        if plot_type != "rtt" && plot_type != "throughput"
            println("Invalid plot type. Please choose either 'rtt' or 'throughput'.")
            return
        end

        data = read_data(file_paths[benchmark_type], max_size_kb)

        # Define folder structure for saving the plots
        base_dir = "src/Scripts/Results"
        folder_name = ""
        if benchmark_type == "pingpong"
            folder_name = "PingpongPlots"
        elseif benchmark_type == "pingpong-io"
            folder_name = "PingpongIoPlots"
        elseif benchmark_type == "nfs"
            folder_name = "NfsPlots"
        elseif benchmark_type == "scp"
            folder_name = "ScpPlots"
        end

        # Create the folder if it doesn't exist
        folder_path = joinpath(base_dir, folder_name)
        if !isdir(folder_path)
            mkdir(folder_path)
        end

        # Set the save path for the plot
        save_path = joinpath(folder_path, "$(benchmark_type)-$(plot_type)-$(max_size_kb)KB.png")

        # Plot the data and save the plot
        plot_data(data, save_path, plot_type)
    else
        println("Invalid choice. Please enter 'all' or 'specific'.")
    end
end

main()