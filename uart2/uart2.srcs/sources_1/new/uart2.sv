`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2024 21:31:23
// Design Name: 
// Module Name: uart2
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



module uart2 (
    input wire clk,              // Reloj del sistema
    input wire reset,            // Señal de reinicio
    input wire rx,               // Línea de recepción de datos seriales
    input wire [7:0] tx_data,    // Datos a transmitir (8 bits)
    input wire tx_start,         // Señal para iniciar la transmisión
    output reg tx,               // Línea de transmisión de datos seriales
    output reg tx_busy,          // Señal que indica si la transmisión está en curso
    output reg [7:0] rx_data,    // Datos recibidos (8 bits)
    output reg rx_ready          // Señal que indica si los datos han sido recibidos
);

    // Parámetros de configuración
    parameter CLK_FREQ = 50000000; // Frecuencia del reloj del sistema (50 MHz)
    parameter BAUD_RATE = 115200;  // Velocidad en baudios (115200 bps)

    // Calculamos el número de ciclos de reloj por bit
    localparam integer CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // Estados para la máquina de estados de transmisión
    typedef enum logic [2:0] {
        IDLE,        // Estado inactivo
        START_BIT,   // Transmitiendo bit de inicio
        DATA_BITS,   // Transmitiendo bits de datos
        STOP_BIT     // Transmitiendo bit de parada
    } tx_state_t;

    tx_state_t tx_state;            // Estado actual de la transmisión
    reg [7:0] tx_shift_reg;          // Registro de desplazamiento para la transmisión
    reg [2:0] tx_bit_idx;            // Índice del bit que se está transmitiendo
    reg [15:0] tx_clock_count;       // Contador de ciclos de reloj

    // Estados para la máquina de estados de recepción
    typedef enum logic [2:0] {
        RX_IDLE,     // Estado inactivo
        RX_START_BIT,// Recibiendo bit de inicio
        RX_DATA_BITS,// Recibiendo bits de datos
        RX_STOP_BIT  // Recibiendo bit de parada
    } rx_state_t;

    rx_state_t rx_state;             // Estado actual de la recepción
    reg [7:0] rx_shift_reg;          // Registro de desplazamiento para la recepción
    reg [2:0] rx_bit_idx;            // Índice del bit que se está recibiendo
    reg [15:0] rx_clock_count;       // Contador de ciclos de reloj

    // Lógica de transmisión
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1'b1;              // Línea de transmisión en reposo (alto)
            tx_state <= IDLE;        // Estado inicial de la transmisión
            tx_busy <= 1'b0;         // No hay transmisión en curso
            tx_shift_reg <= 8'd0;    // Limpia el registro de desplazamiento
            tx_bit_idx <= 3'd0;      // Limpia el índice de bits
            tx_clock_count <= 16'd0; // Limpia el contador de ciclos de reloj
        end else begin
            case (tx_state)
                IDLE: begin
                    if (tx_start) begin
                        tx_state <= START_BIT;    // Inicia la transmisión con el bit de inicio
                        tx_shift_reg <= tx_data;  // Carga los datos a transmitir en el registro de desplazamiento
                        tx <= 1'b0;               // Envía el bit de inicio (bajo)
                        tx_busy <= 1'b1;          // Indica que la transmisión está en curso
                        tx_clock_count <= 16'd0;  // Reinicia el contador de ciclos de reloj
                    end
                end
                START_BIT: begin
                    if (tx_clock_count == CLOCKS_PER_BIT - 1) begin
                        tx_clock_count <= 16'd0;  // Reinicia el contador de ciclos de reloj
                        tx_state <= DATA_BITS;    // Pasa al estado de transmisión de bits de datos
                        tx_bit_idx <= 3'd0;       // Reinicia el índice de bits
                    end else begin
                        tx_clock_count <= tx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
                DATA_BITS: begin
                    if (tx_clock_count == CLOCKS_PER_BIT - 1) begin
                        tx_clock_count <= 16'd0;  // Reinicia el contador de ciclos de reloj
                        tx <= tx_shift_reg[0];    // Envía el siguiente bit de datos
                        tx_shift_reg <= tx_shift_reg >> 1; // Desplaza los datos a la derecha
                        if (tx_bit_idx == 7) begin
                            tx_state <= STOP_BIT; // Si se han enviado todos los bits de datos, pasa al bit de parada
                        end else begin
                            tx_bit_idx <= tx_bit_idx + 1;  // Incrementa el índice de bits
                        end
                    end else begin
                        tx_clock_count <= tx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
                STOP_BIT: begin
                    if (tx_clock_count == CLOCKS_PER_BIT - 1) begin
                        tx_state <= IDLE;          // Vuelve al estado inactivo
                        tx <= 1'b1;                // Envía el bit de parada (alto)
                        tx_busy <= 1'b0;           // Indica que la transmisión ha terminado
                    end else begin
                        tx_clock_count <= tx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
            endcase
        end
    end

    // Lógica de recepción
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_state <= RX_IDLE;      // Estado inicial de la recepción
            rx_ready <= 1'b0;         // No hay datos listos
            rx_shift_reg <= 8'd0;     // Limpia el registro de desplazamiento
            rx_bit_idx <= 3'd0;       // Limpia el índice de bits
            rx_clock_count <= 16'd0;  // Limpia el contador de ciclos de reloj
        end else begin
            case (rx_state)
                RX_IDLE: begin
                    if (~rx) begin    // Detecta el inicio de la recepción (bit de inicio)
                        rx_state <= RX_START_BIT;  // Pasa al estado de recepción del bit de inicio
                        rx_clock_count <= CLOCKS_PER_BIT / 2;  // Configura el contador de ciclos de reloj para muestreo en el medio del bit
                    end
                end
                RX_START_BIT: begin
                    if (rx_clock_count == CLOCKS_PER_BIT - 1) begin
                        rx_clock_count <= 16'd0;  // Reinicia el contador de ciclos de reloj
                        rx_state <= RX_DATA_BITS; // Pasa al estado de recepción de bits de datos
                        rx_bit_idx <= 3'd0;       // Reinicia el índice de bits
                    end else begin
                        rx_clock_count <= rx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
                RX_DATA_BITS: begin
                    if (rx_clock_count == CLOCKS_PER_BIT - 1) begin
                        rx_clock_count <= 16'd0;  // Reinicia el contador de ciclos de reloj
                        rx_shift_reg <= {rx, rx_shift_reg[7:1]};  // Desplaza el bit recibido al registro de desplazamiento
                        if (rx_bit_idx == 7) begin
                            rx_state <= RX_STOP_BIT; // Si se han recibido todos los bits de datos, pasa al bit de parada
                        end else begin
                            rx_bit_idx <= rx_bit_idx + 1;  // Incrementa el índice de bits
                        end
                    end else begin
                        rx_clock_count <= rx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
                RX_STOP_BIT: begin
                    if (rx_clock_count == CLOCKS_PER_BIT - 1) begin
                        rx_state <= RX_IDLE;      // Vuelve al estado inactivo
                        rx_ready <= 1'b1;        // Indica que los datos están listos
                        rx_data <= rx_shift_reg; // Almacena los datos recibidos
                    end else begin
                        rx_clock_count <= rx_clock_count + 1;  // Incrementa el contador de ciclos de reloj
                    end
                end
            endcase
        end
    end

endmodule