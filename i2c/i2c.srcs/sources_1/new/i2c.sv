`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2024 21:32:27
// Design Name: 
// Module Name: i2c
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c (
    input logic clk,              // Reloj de entrada
    input logic rst_n,            // Reset activo bajo
    input logic start,            // Señal de inicio para la transmisión I2C
    input logic [6:0] address,    // Dirección del esclavo I2C (7 bits)
    input logic read_write,       // Señal para indicar lectura (1) o escritura (0)
    input logic [7:0] data_in,    // Datos de entrada para escritura
    output logic [7:0] data_out,  // Datos de salida para lectura
    output logic sda,             // Línea de datos seriales I2C
    output logic scl,             // Línea de reloj I2C
    output logic busy,            // Señal para indicar que el módulo está ocupado
    output logic ack_error        // Señal de error de reconocimiento
);

    // Parámetros para los estados del FSM (Máquina de Estados Finitos)
    typedef enum logic [2:0] {
        IDLE,       // Estado de inactividad
        START,      // Estado de inicio
        ADDR,       // Estado de transmisión de dirección
        RW,         // Estado de transmisión de bit de lectura/escritura
        DATA,       // Estado de transmisión/recepción de datos
        ACK,        // Estado de espera de ACK/NACK
        STOP        // Estado de parada
    } state_t;
    state_t state, next_state;    // Estado actual y siguiente de la FSM

    logic [3:0] bit_count;        // Contador de bits para transmisión de 8 bits

    // Lógica secuencial para actualizar el estado de la FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;        // Resetear al estado IDLE
        end else begin
            state <= next_state;  // Actualizar al siguiente estado
        end
    end

    // Lógica combinacional para definir el siguiente estado y las salidas
    always_comb begin
        // Valores por defecto para las señales de salida
        next_state = state;
        busy = 1'b1;
        sda = 1'b1;
        scl = 1'b1;
        ack_error = 1'b0;
        data_out = 8'b0;

        case (state)
            IDLE: begin
                busy = 1'b0;
                if (start) begin
                    next_state = START;  // Iniciar transmisión si la señal de inicio está activa
                end
            end
            START: begin
                sda = 1'b0;             // Generar la condición de inicio (SDA baja mientras SCL está alta)
                next_state = ADDR;
            end
            ADDR: begin
                sda = address[bit_count];  // Transmitir dirección bit a bit
                if (bit_count == 7) begin
                    next_state = RW;
                end else begin
                    bit_count = bit_count + 1;
                end
            end
            RW: begin
                sda = read_write;         // Transmitir bit de lectura/escritura
                next_state = ACK;
            end
            DATA: begin
                if (read_write) begin
                    // Lógica de recepción de datos
                    data_out[bit_count] = sda;
                end else begin
                    // Lógica de transmisión de datos
                    sda = data_in[bit_count];
                end
                if (bit_count == 7) begin
                    next_state = ACK;
                end else begin
                    bit_count = bit_count + 1;
                end
            end
            ACK: begin
                if (sda == 1'b0) begin
                    ack_error = 1'b1;    // Error de reconocimiento si SDA es alto
                end
                if (read_write) begin
                    next_state = DATA;
                end else begin
                    next_state = STOP;
                end
            end
            STOP: begin
                sda = 1'b0;
                scl = 1'b0;
                sda = 1'b1;              // Generar la condición de parada (SDA alta mientras SCL está alto)
                next_state = IDLE;
            end
        endcase
    end

endmodule
