//DEADLINE based scheduler

// Code your design here

module DEADLINE_SCHEDULER(
    input logic clk,
    input logic reset,
    input logic new_task,          // Signal to indicate a new task is being added
    input int deadline,            // Relative deadline of the new task
    output reg task_scheduled,     // Indicates a task is scheduled
    output reg [31:0] scheduled_task_id  // ID of the scheduled task
);

    localparam MAX_TASKS = 8;  // Maximum number of tasks the scheduler can handle
    typedef struct packed {
        int deadline;           // Deadline relative to the task's submission time
        int id;                 // Task ID
        logic valid;            // Valid bit to indicate if the slot is occupied
    } task_t;

    task_t tasks[MAX_TASKS];  // Array to store tasks
    int current_time = 0;     // Current time counter
    int min_time;// = 2147483647;
    int min_index;// = -1;

    // Process to handle tasks and scheduling
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
            current_time <= 0;
            for (int i = 0; i < MAX_TASKS; i++) begin
                tasks[i].valid <= 0;
            end
            task_scheduled <= 0;
        end 
        else begin
            current_time <= current_time + 1;  // Increment current time

            // Check for new task
            if (new_task) begin
                for (int i = 0; i < MAX_TASKS; i++) begin
                    if (!tasks[i].valid) begin
                        tasks[i].deadline = current_time + deadline;
                        tasks[i].id = current_time;  // Simple way to generate a unique ID
                        tasks[i].valid = 1;
                        break;
                    end
                end
            end

            // Find the task with the nearest deadline
            min_time = 2147483647;
            min_index = -1;
            for (int i = 0; i < MAX_TASKS; i++) begin
                if (tasks[i].valid && tasks[i].deadline < min_time) begin
                    min_time = tasks[i].deadline;
                    min_index = i;
                end
            end

            // Schedule the task with the closest deadline
            if (min_index != -1 && tasks[min_index].deadline <= current_time) begin
                task_scheduled <= 1;
                scheduled_task_id <= tasks[min_index].id;
                tasks[min_index].valid <= 0;  // Mark this task as processed
            end else begin
                task_scheduled <= 0;
            end
        end
    end
endmodule
