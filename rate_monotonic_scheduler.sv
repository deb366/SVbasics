
//Code is WIP
module rate_monotonic_scheduler(
    input logic clk,
    input logic reset,
    output logic [31:0] task_id_to_run
);

    typedef struct packed {
        int id;
        int period;
        int next_run_time;
    } task_t;

    // Example tasks (statically defined for synthesis)
    localparam int NUM_TASKS = 3;
    task_t tasks[NUM_TASKS] = '{
        {1, 10, 10},  // Task 1 runs every 10 units
        {2, 20, 20},  // Task 2 runs every 20 units
        {3, 40, 40}   // Task 3 runs every 40 units
    };
  	task_t highest_priority_task;

    // Current time in system ticks
    int current_time = 0;

    always_ff @(posedge clk) begin
        if (reset) begin
            current_time <= 0;
            task_id_to_run <= 0;
            // Reset next_run_time to their initial periods
            for (int i = 0; i < NUM_TASKS; i++) begin
                tasks[i].next_run_time <= tasks[i].period;
            end
        end else begin
            current_time <= current_time + 1;
            highest_priority_task = '{default:0};

            // Find the task with the earliest next_run_time
            for (int i = 0; i < NUM_TASKS; i++) begin
                if (tasks[i].next_run_time == current_time) begin
                    if (highest_priority_task.id == 0 || tasks[i].period < highest_priority_task.period) begin
                        highest_priority_task = tasks[i];
                    end
                end
            end

            // Set the output to run this task
            if (highest_priority_task.id != 0) begin
                task_id_to_run <= highest_priority_task.id;
                // Update the next run time for this task
                for (int i = 0; i < NUM_TASKS; i++) begin
                    if (tasks[i].id == highest_priority_task.id) begin
                        tasks[i].next_run_time <= current_time + tasks[i].period;
                        break;
                    end
                end
            end else begin
                task_id_to_run <= 0; // No task to run
            end
        end
    end
endmodule
