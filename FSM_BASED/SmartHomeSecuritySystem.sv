/*
Develop an FSM-based smart home security system in SystemVerilog. The system should manage various sensors (motion, window/door, smoke) and make decisions based on the input from these devices.
*/

module SmartHomeSecuritySystem(
    input logic clk, reset,
    input logic manual_config, manual_disarm, manual_arm_home, manual_resolve, resident, self_test_done,
    input logic door_window_sensor, motion_sensor, smoke_sensor, temp_sensor,
    input logic [7:0] temperature,  // Assuming temperature is an 8-bit value
    output logic call_police, call_ambulance, sound_alarm
);

    typedef enum logic [3:0] {
        S_INIT, S_IDLE, S_DISARMED,
        S_ARMED_HOME, S_ARMED_AWAY,
        S_ALARM, S_CHECK_TMP,
        S_ERROR
    } state_t;

    state_t current_state, next_state;

    // State transition logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= S_INIT;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;  // Default state: hold state
        case (current_state)
            S_INIT: if (self_test_done) next_state = S_IDLE;
            S_IDLE: begin
                if (manual_config) next_state = S_DISARMED;
                else if (manual_arm_home) next_state = S_ARMED_HOME;
            end
            S_DISARMED: if (manual_arm_home && resident) next_state = S_ARMED_HOME;
            S_ARMED_HOME: if (!resident) next_state = S_ARMED_AWAY;
            S_ARMED_AWAY: begin
                if (door_window_sensor) next_state = S_ALARM;
                if (smoke_sensor) next_state = S_CHECK_TMP;
            end
            S_ALARM: if (manual_resolve) next_state = S_ARMED_AWAY; // Added manual resolve transition
            S_CHECK_TMP: if (manual_resolve) next_state = S_ARMED_AWAY; // Added manual resolve transition
        endcase
    end

    // Actions based on state
    always_ff @(posedge clk) begin
        call_police <= 0;
        call_ambulance <= 0;
        sound_alarm <= 0;

        case (current_state)
            S_ALARM: begin
                if (motion_sensor) call_police <= 1;
                if (door_window_sensor) sound_alarm <= 1;
            end
            S_CHECK_TMP: if (temperature > 50) call_ambulance <= 1;
        endcase
    end
endmodule
