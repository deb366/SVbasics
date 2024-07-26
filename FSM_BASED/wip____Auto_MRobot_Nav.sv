/*
Autonomous Mobile Robot Navigation
Basic Navigation States
Idle: The robot is stationary, not currently engaged in active navigation or tasks.
Moving: The robot is actively moving towards a designated target location.
Pause: The robot temporarily stops moving, perhaps due to an external command or operational assessment.
Obstacle Detection and Avoidance States
Obstacle Detected: Sensors identify an obstacle in the robot's path.
Calculating Detour: The robot calculates an alternative route to circumvent the obstacle.
Avoiding Obstacle: The robot navigates according to the detour to avoid the obstacle.
Obstacle Cleared: The robot has successfully navigated past the obstacle.
Realigning to Path: The robot adjusts its trajectory to re-align with its original or a newly calculated path.
Resume Navigation: The robot resumes its journey towards the target on the realigned path.
Straight Path Check: The robot evaluates if a straight path is viable for continuing towards the target without further deviations.
Path Optimization: The robot optimizes its route based on updated environmental data and conditions.
Task Management States
Task Assigned: The robot receives and prioritizes a new task.
Task Active: The robot is engaged in executing the current task.
Task Completed: The robot has finished the assigned task and updates the task status or queue.
Error Recovery and System Malfunctions States
Error Detection: An error or malfunction is identified (sensor failure, navigation error, etc.).
Attempting Recovery: The robot attempts to correct the detected error or switch to a backup system.
Recovery Failed: Attempts to fix the error have failed; the robot may require human intervention.
Recovery Succeeded: The robot has successfully corrected the error and returns to normal operation.
Power Management States
Monitor Battery: Ongoing monitoring of the battery level during operations.
Low Battery: The battery level is critically low; the robot needs to return to the charging station.
Charging: The robot is connected to a charging station and is recharging.
Charged: The robot is fully charged and ready to resume or start new tasks.
//Code can be enhanced by the above ideas
*/
module Auto_MRobot_Nav(
    input logic clk,
    input logic reset_n,
    input logic[2:0] sensor_input,   // Sensor inputs potentially indicating obstacles
    input logic destination_reached, // Signal indicating that the robot has reached the destination
    input logic error_detected,      // Signal for any errors or malfunctions
    output logic[2:0] state,         // Current state of the FSM
    output logic drive,              // Control signal to drive the robot
    output logic resolve_collision,  // Control signal to resolve collision
    output logic perform_delivery,   // Control signal for delivery action
    output logic manage_recovery     // Control signal for managing recovery
);

    // State encoding
    typedef enum logic[2:0] {
        CHECK_ROUTE = 3'b000,
        WALKING = 3'b001,
        COLLISION_RESOLUTION = 3'b010,
        DELIVERY = 3'b011,
        RECOVERY = 3'b100
    } state_t;

    // Current and next state definition
    state_t current_state, next_state;

    // FSM next state logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            current_state <= CHECK_ROUTE;
        else
            current_state <= next_state;
    end

    // FSM output logic and transitions
    always_comb begin
        // Defaults for outputs
        drive = 0;
        resolve_collision = 0;
        perform_delivery = 0;
        manage_recovery = 0;
        next_state = current_state;

        case (current_state)
            CHECK_ROUTE: begin
                // Determine best route based on sensor inputs or internal logic
                next_state = WALKING; // Simplified assumption
            end
            WALKING: begin
                drive = 1; // Activate driving mechanism
                if (sensor_input != 0) 
                    next_state = COLLISION_RESOLUTION;
                else if (destination_reached)
                    next_state = DELIVERY;
                else if (error_detected)
                    next_state = RECOVERY;
            end
            COLLISION_RESOLUTION: begin
                resolve_collision = 1; // Activate collision resolution mechanism
                next_state = WALKING;  // Assume collision can be resolved and return to WALKING
            end
            DELIVERY: begin
                perform_delivery = 1; // Perform delivery actions
                next_state = CHECK_ROUTE; // Check route for next task
            end
            RECOVERY: begin
                manage_recovery = 1; // Handle any malfunctions or errors
                next_state = CHECK_ROUTE; // Return to route checking after recovery
            end
            default: begin
                next_state = RECOVERY; // Fallback to recovery on undefined states
            end
        endcase
    end

    // Output current state to external monitoring or logging
    assign state = current_state;

endmodule

