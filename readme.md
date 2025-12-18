# Proyecto: ADC_TXRX (Conversión A/D y Comunicación Serial)

## Descripción General

Este proyecto implementa la funcionalidad básica de un Conversor Analógico a Digital (ADC) en un microcontrolador AVR y permite al usuario seleccionar dinámicamente la resolución del ADC (8 o 10 bits) a través de la comunicación serial (UART).

El código lee continuamente el valor del ADC (en el canal 0 por defecto) y lo transmite por UART como una cadena de texto decimal (ASCII).



## Características Clave

* **Comunicación Serial (UART):** Configurada a **9600 baudios** (asumiendo un reloj de sistema de 16MHz) para recibir comandos y transmitir resultados.
* **ADC Dinámico:** Permite cambiar la resolución del ADC en tiempo de ejecución.
* **Soporte de Resolución:**
    * **8 bits:** Utiliza el registro `ADCH` para el resultado, con alineación a la izquierda (`ADLAR=1` en `ADMUX`).
    * **10 bits:** Utiliza los registros `ADCL` y `ADCH` para el resultado, con alineación a la derecha (`ADLAR=0` en `ADMUX`).
* **Transmisión de Datos:** El valor convertido del ADC se descompone en sus dígitos decimales y se envía por UART como caracteres ASCII, seguido de un salto de línea (`0x0A`).

## Comandos Seriales

El programa espera recibir un *byte* por el puerto serial para cambiar la configuración del ADC:

| Byte Recibido (Decimal) | Byte Recibido (Hex) | Acción |
| :---------------------- | :------------------ | :----- |
| 8                       | 0x08                | Configura el ADC a 8 bits (`ADC8_INIT`). |
| 16                      | 0x10                | Configura el ADC a 10 bits (`ADC10_INIT`). |

Cualquier otro dato recibido es ignorado. El modo por defecto al inicio es 8 bits.


## Licencia

Este proyecto está licenciado bajo la Licencia **MIT**.


Consulte el archivo [LICENSE](LICENSE.txt) para obtener los detalles completos.
