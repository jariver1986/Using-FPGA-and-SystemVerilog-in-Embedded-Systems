`timescale 1ns / 1ps

module i2c_tb;

    // Señales del testbench
    logic clk;
    logic rst_n;
    logic start;
    logic [6:0] address;
    logic read_write;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic sda;
    logic scl;
    logic busy;
    logic ack_error;

    // Instancia del módulo I2C
    i2c uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .address(address),
        .read_write(read_write),
        .data_in(data_in),
        .data_out(data_out),
        .sda(sda),
        .scl(scl),
        .busy(busy),
        .ack_error(ack_error)
    );

    // Generación del reloj
    always #5 clk = ~clk;

    // Proceso de prueba
    initial begin
        // Inicialización de señales
        clk = 0;
        rst_n = 0;
        start = 0;
        address = 7'b0;
        read_write = 0;
        data_in = 8'b0;

        // Reset del módulo
        #10 rst_n = 1;

        // Esperar un ciclo de reloj
        #10;

        // Iniciar una transmisión I2C (Escritura)
        start = 1;
        address = 7'h55;       // Dirección del esclavo
        read_write = 0;        // Escritura
        data_in = 8'hA5;       // Datos a escribir
        #10 start = 0;         // Desactivar señal de inicio

        // Esperar hasta que la transmisión termine
        wait (!busy);

        // Verificar los resultados
        if (ack_error) begin
            $display("Error de reconocimiento durante la escritura");
        end else begin
            $display("Escritura exitosa");
        end

        // Iniciar una transmisión I2C (Lectura)
        start = 1;
        address = 7'h55;       // Dirección del esclavo
        read_write = 1;        // Lectura
        #10 start = 0;         // Desactivar señal de inicio

        // Esperar hasta que la transmisión termine
        wait (!busy);

        // Verificar los resultados
        if (ack_error) begin
            $display("Error de reconocimiento durante la lectura");
        end else begin
            $display("Lectura exitosa, Datos recibidos: %h", data_out);
        end

        // Finalizar simulación
        $stop;
    end
endmodule
