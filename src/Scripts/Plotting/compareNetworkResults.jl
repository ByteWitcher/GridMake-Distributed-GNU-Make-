using PyPlot

function read_data(file_path::String, max_size_kb::Int)
    data = []
    pattern = r"Size:\s*(\d+)\s*KB,\s*RTT:\s*([\d\.]+)\s*ms,\s*Throughput:\s*([\d\.]+)\s*Mbytes/s"
    start_reading = false
    start_sentence = "Average metrics by size:"

    open(file_path, "r") do file
        for line in eachline(file)
            if occursin(start_sentence, line)
                start_reading = true
                continue
            end
            if start_reading
                match_obj = Base.match(pattern, line)
                if match_obj !== nothing
                    size = parse(Int, match_obj.captures[1])
                    if size > max_size_kb
                        break
                    end
                    rtt = parse(Float64, match_obj.captures[2])
                    throughput = parse(Float64, match_obj.captures[3])
                    push!(data, (rtt, throughput, size))
                end
            end
        end
    end

    return data
end

function plot_comparison(data1, data2, label1, label2, save_path, plot_type)
    if plot_type == "rtt"
        values1 = [d[1] for d in data1]
        values2 = [d[1] for d in data2]
        ylabel = "RTT (ms)"
        color1 = "tab:red"
        color2 = "tab:blue"
        title_plot_type = "RTT"
    elseif plot_type == "throughput"
        values1 = [d[2] for d in data1]
        values2 = [d[2] for d in data2]
        ylabel = "Throughput (Mbytes/s)"
        color1 = "tab:orange"
        color2 = "tab:green"
        title_plot_type = "Throughput"
    else
        println("Invalid plot type: $plot_type. Please choose 'rtt' or 'throughput'.")
        return
    end

    sizes1 = [d[3] for d in data1]
    sizes2 = [d[3] for d in data2]

    fig, ax1 = subplots()
    ax1.set_xlabel("Size (KB)")
    ax1.set_ylabel(ylabel)

    ax1.plot(sizes1, values1, color=color1, marker="o", label=label1)
    ax1.plot(sizes2, values2, color=color2, marker="x", label=label2)

    ax1.legend()
    
    ax1.set_title("$title_plot_type comparison: $label1 vs $label2")
    grid(true)

    fig.tight_layout()
    savefig(save_path)
    println("Plot saved as $save_path")
end

function main()
    println("Enter the maximum size in KB to read (e.g., 100): ")
    max_size_kb = parse(Int, readline())

    println("Do you want to run all combinations or a specific combination? ('all' or 'specific')")
    run_choice = string(strip(readline()))

    if run_choice == "all"
        comparison_types = ["pingpong", "nfs-scp"]
        plot_types = ["rtt", "throughput"]

        for comparison_type in comparison_types
            for plot_type in plot_types
                println("Running for comparison: $comparison_type, plot type: $plot_type")

                file_paths = Dict(
                    "pingpong" => ("src/Scripts/Results/pingpong-results.txt", "src/Scripts/Results/pingpong-io-results.txt"),
                    "nfs-scp" => ("src/Scripts/Results/nfs-results.txt", "src/Scripts/Results/scp-results.txt")
                )

                file_path_1, file_path_2 = file_paths[comparison_type]
                data1 = read_data(file_path_1, max_size_kb)
                data2 = read_data(file_path_2, max_size_kb)

                if comparison_type == "pingpong"
                    label1 = "Ping Pong"
                    label2 = "Ping Pong IO"
                    folder_name = "PingpongComparisonPlots"
                elseif comparison_type == "nfs-scp"
                    label1 = "NFS"
                    label2 = "SCP"
                    folder_name = "NfsScpComparisonPlots"
                end

                base_dir = "src/Scripts/Results"
                folder_path = joinpath(base_dir, folder_name)
                if !isdir(folder_path)
                    mkdir(folder_path)
                end

                save_path = joinpath(folder_path, "$(comparison_type)-comparison-$(plot_type)-$(max_size_kb)KB.png")
                plot_comparison(data1, data2, label1, label2, save_path, plot_type)
            end
        end
    elseif run_choice == "specific"
        println("Enter the type of comparison ('pingpong' or 'nfs-scp'): ")
        comparison_type = string(strip(readline()))

        file_paths = Dict(
            "pingpong" => ("src/Scripts/Results/pingpong-results.txt", "src/Scripts/Results/pingpong-io-results.txt"),
            "nfs-scp" => ("src/Scripts/Results/nfs-results.txt", "src/Scripts/Results/scp-results.txt")
        )

        if !haskey(file_paths, comparison_type)
            println("Invalid comparison type '$comparison_type'. Please choose either 'pingpong' or 'nfs-scp'.")
            return
        end

        file_path_1, file_path_2 = file_paths[comparison_type]

        println("Do you want to plot 'rtt' or 'throughput'?")
        plot_type = string(strip(readline()))

        if plot_type != "rtt" && plot_type != "throughput"
            println("Invalid plot type. Please choose either 'rtt' or 'throughput'.")
            return
        end

        data1 = read_data(file_path_1, max_size_kb)
        data2 = read_data(file_path_2, max_size_kb)

        if comparison_type == "pingpong"
            label1 = "Ping Pong"
            label2 = "Ping Pong IO"
            folder_name = "PingpongComparisonPlots"
        elseif comparison_type == "nfs-scp"
            label1 = "NFS"
            label2 = "SCP"
            folder_name = "NfsScpComparisonPlots"
        end

        base_dir = "src/Scripts/Results"
        folder_path = joinpath(base_dir, folder_name)
        if !isdir(folder_path)
            mkdir(folder_path)
        end

        save_path = joinpath(folder_path, "$(comparison_type)-comparison-$(plot_type)-$(max_size_kb)KB.png")
        plot_comparison(data1, data2, label1, label2, save_path, plot_type)
    else
        println("Invalid choice. Please enter 'all' or 'specific'.")
    end
end

main()
