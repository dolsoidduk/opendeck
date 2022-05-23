#!/usr/bin/env bash

if [[ "$($yaml_parser "$yaml_file" leds.external)" != "null" ]]
then
    printf "%s\n" "DEFINES += DIGITAL_OUTPUTS_SUPPORTED" >> "$out_makefile"

    digital_out_type=$($yaml_parser "$yaml_file" leds.external.type)

    declare -i nr_of_digital_outputs
    nr_of_digital_outputs=0

    if [[ $digital_out_type == "native" ]]
    then
        printf "%s\n" "DEFINES += DIGITAL_OUTPUT_DRIVER_NATIVE" >> "$out_makefile"

        nr_of_digital_outputs=$($yaml_parser "$yaml_file" leds.external.pins --length)

        unset port_duplicates
        unset port_array
        unset index_array
        unset port_array_unique
        declare -A port_duplicates
        declare -a port_array
        declare -a index_array
        declare -a port_array_unique

        for ((i=0; i<nr_of_digital_outputs; i++))
        do
            port=$($yaml_parser "$yaml_file" leds.external.pins.["$i"].port)
            index=$($yaml_parser "$yaml_file" leds.external.pins.["$i"].index)

            port_array+=("$port")
            index_array+=("$index")

            {
                printf "%s\n" "#define DOUT_PORT_${i} CORE_MCU_IO_PIN_PORT_DEF(${port})"
                printf "%s\n" "#define DOUT_PIN_${i} CORE_MCU_IO_PIN_INDEX_DEF(${index})"
            } >> "$out_header"

            if [[ -z ${port_duplicates[$port]} ]]
            then
                port_array_unique+=("$port")
            fi

            port_duplicates["$port"]=1
        done

        {
            printf "%s\n" "#define NR_OF_DIGITAL_OUTPUT_PORTS ${#port_array_unique[@]}"
            printf "%s\n" "namespace {"
            printf "%s\n" "constexpr inline core::mcu::io::pinPort_t D_OUT_PORTS[NR_OF_DIGITAL_OUTPUT_PORTS] = {"
        } >> "$out_header"

        for ((i=0; i<${#port_array_unique[@]}; i++))
        do
            {
                printf "%s\n" "CORE_MCU_IO_PIN_PORT_DEF(${port_array_unique[$i]}),"
            } >> "$out_header"
        done

        {
            printf "%s\n" "};"
            printf "%s\n" "constexpr inline core::mcu::io::portWidth_t D_OUT_PORTS_CLEAR_MASK[NR_OF_DIGITAL_OUTPUT_PORTS] = {"
        } >> "$out_header"

        for ((port=0; port<${#port_array_unique[@]}; port++))
        do
            unset mask
            declare -i mask
            mask=0xFFFFFFFF

            for ((i=0; i<nr_of_digital_outputs; i++))
            do
                if [[ ${port_array[$i]} == "${port_array_unique[$port]}" ]]
                then
                    ((mask&=~(1 << index_array[i])))
                fi
            done

            printf "%s\n" "static_cast<core::mcu::io::portWidth_t>($mask)," >> "$out_header"
        done

        {
            printf "%s\n" "};"
            printf "%s\n" "constexpr inline core::mcu::io::pin_t D_OUT_PINS[NR_OF_DIGITAL_OUTPUTS] = {"
        } >> "$out_header"

        for ((i=0; i<nr_of_digital_outputs; i++))
        do
            printf "%s\n" "CORE_MCU_IO_PIN_VAR(DOUT_PORT_${i}, DOUT_PIN_${i})," >> "$out_header"
        done

        {
            printf "%s\n" "};" >> "$out_header"
            printf "%s\n" "constexpr inline uint8_t LED_INDEX_TO_UNIQUE_PORT_INDEX[NR_OF_DIGITAL_OUTPUTS] = {"
        } >> "$out_header"

        for ((i=0; i<nr_of_digital_outputs; i++))
        do
            for ((port=0; port<${#port_array_unique[@]}; port++))
            do
                if [[ ${port_array[$i]} == "${port_array_unique[$port]}" ]]
                then
                    printf "%s\n" "$port," >> "$out_header"
                fi
            done
        done

        {
            printf "%s\n" "};" >> "$out_header"
            printf "%s\n" "constexpr inline uint8_t LED_INDEX_TO_PIN_INDEX[NR_OF_DIGITAL_OUTPUTS] = {"
        } >> "$out_header"

        for ((i=0; i<nr_of_digital_outputs; i++))
        do
            printf "%s\n" "${index_array[i]}," >> "$out_header"
        done

        {
            printf "%s\n" "};" >> "$out_header"
            printf "%s\n" "}"
        } >> "$out_header"
    elif [[ $digital_out_type == shiftRegister ]]
    then
        printf "%s\n" "DEFINES += DIGITAL_OUTPUT_DRIVER_SHIFT_REGISTER" >> "$out_makefile"

        port=$($yaml_parser "$yaml_file" leds.external.pins.data.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.data.index)

        {
            printf "%s\n" "#define SR_OUT_DATA_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define SR_OUT_DATA_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.external.pins.clock.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.clock.index)

        {
            printf "%s\n" "#define SR_OUT_CLK_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define SR_OUT_CLK_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.external.pins.latch.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.latch.index)

        {
            printf "%s\n" "#define SR_OUT_LATCH_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define SR_OUT_LATCH_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.external.pins.enable.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.enable.index)

        {
            printf "%s\n" "#define SR_OUT_OE_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define SR_OUT_OE_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        number_of_out_sr=$($yaml_parser "$yaml_file" leds.external.shiftRegisters)
        nr_of_digital_outputs=$((number_of_out_sr * 8))

        printf "%s\n" "DEFINES += NUMBER_OF_OUT_SR=$number_of_out_sr" >> "$out_makefile"
    elif [[ $digital_out_type == matrix ]]
    then
        printf "%s\n" "DEFINES += DIGITAL_OUTPUT_DRIVER_MATRIX_NATIVE_ROWS" >> "$out_makefile"

        number_of_led_columns=8
        number_of_led_rows=$($yaml_parser "$yaml_file" leds.external.rows.pins --length)

        for ((i=0; i<3; i++))
        do
            port=$($yaml_parser "$yaml_file" leds.external.columns.pins.decA"$i".port)
            index=$($yaml_parser "$yaml_file" leds.external.columns.pins.decA"$i".index)

            {
                printf "%s\n" "#define DEC_LM_PORT_A${i} CORE_MCU_IO_PIN_PORT_DEF(${port})"
                printf "%s\n" "#define DEC_LM_PIN_A${i} CORE_MCU_IO_PIN_INDEX_DEF(${index})"
            } >> "$out_header"
        done

        for ((i=0; i<"$number_of_led_rows"; i++))
        do
            port=$($yaml_parser "$yaml_file" leds.external.rows.pins.["$i"].port)
            index=$($yaml_parser "$yaml_file" leds.external.rows.pins.["$i"].index)

            {
                printf "%s\n" "#define LED_ROW_PORT_${i} CORE_MCU_IO_PIN_PORT_DEF(${port})"
                printf "%s\n" "#define LED_ROW_PIN_${i} CORE_MCU_IO_PIN_INDEX_DEF(${index})"
            } >> "$out_header"
        done

        {
            printf "%s\n" "namespace {"
            printf "%s\n" "constexpr inline core::mcu::io::pin_t D_OUT_PINS[NUMBER_OF_LED_ROWS] = {"
        } >> "$out_header"

        for ((i=0; i<"$number_of_led_rows"; i++))
        do
            printf "%s\n" "CORE_MCU_IO_PIN_VAR(LED_ROW_PORT_${i}, LED_ROW_PIN_${i})," >> "$out_header"
        done

        {
            printf "%s\n" "};"
            printf "%s\n" "}"
        } >> "$out_header"

        nr_of_digital_outputs=$(("$number_of_led_columns" * "$number_of_led_rows"))

        {
            printf "%s\n" "DEFINES += NUMBER_OF_LED_COLUMNS=$number_of_led_columns"
            printf "%s\n" "DEFINES += NUMBER_OF_LED_ROWS=$number_of_led_rows"
        } >> "$out_makefile"
    elif [[ $digital_out_type == max7219 ]]
    then
        printf "%s\n" "DEFINES += DIGITAL_OUTPUT_DRIVER_MAX7219" >> "$out_makefile"

        port=$($yaml_parser "$yaml_file" leds.external.pins.data.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.data.index)

        {
            printf "%s\n" "#define MAX7219_DATA_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define MAX7219_DATA_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.external.pins.clock.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.clock.index)

        {
            printf "%s\n" "#define MAX7219_CLK_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define MAX7219_CLK_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.external.pins.latch.port)
        index=$($yaml_parser "$yaml_file" leds.external.pins.latch.index)

        {
            printf "%s\n" "#define MAX7219_LATCH_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define MAX7219_LATCH_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        # hardcode for now
        nr_of_digital_outputs=64
    fi

    if [[ "$($yaml_parser "$yaml_file" leds.external.indexing)" != "null" ]]
    then
        nr_of_digital_outputs=$($yaml_parser "$yaml_file" leds.external.indexing --length)

        {
            printf "%s\n" "namespace {"
            printf "%s\n" "constexpr inline uint8_t LED_INDEXES[NR_OF_DIGITAL_OUTPUTS] = {"
        } >> "$out_header"

        for ((i=0; i<nr_of_digital_outputs; i++))
        do
            index=$($yaml_parser "$yaml_file" leds.external.indexing.["$i"])
            printf "%s\n" "${index}," >> "$out_header"
        done

        {
            printf "%s\n" "};"
            printf "%s\n" "}"
        } >> "$out_header"

        printf "%s\n" "DEFINES += LED_INDEXING" >> "$out_makefile"
    fi

    {
        printf "%s\n" "DEFINES += NR_OF_DIGITAL_OUTPUTS=$nr_of_digital_outputs"
    } >> "$out_makefile"

    if [[ "$($yaml_parser "$yaml_file" leds.external.invert)" == "true" ]]
    then
        printf "%s\n" "DEFINES += LED_EXT_INVERT" >> "$out_makefile"
    fi
else
    {
        printf "%s\n" "DEFINES += NR_OF_DIGITAL_OUTPUTS=0"
    } >> "$out_makefile"
fi

if [[ "$($yaml_parser "$yaml_file" leds.internal)" != "null" ]]
then
    printf "%s\n" "DEFINES += LED_INDICATORS" >> "$out_makefile"
    printf "%s\n" "DEFINES += LED_INDICATORS_CTL" >> "$out_makefile"

    if [[ "$($yaml_parser "$yaml_file" leds.internal.invert)" == "true" ]]
    then
        printf "%s\n" "DEFINES += LED_INT_INVERT" >> "$out_makefile"
    fi

    if [[ $($yaml_parser "$yaml_file" leds.internal.pins.din) != "null" ]]
    then
        port=$($yaml_parser "$yaml_file" leds.internal.pins.din.rx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.din.rx.index)

        {
            printf "%s\n" "#define LED_MIDI_IN_DIN_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_IN_DIN_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.internal.pins.din.tx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.din.tx.index)

        {
            printf "%s\n" "#define LED_MIDI_OUT_DIN_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_OUT_DIN_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"
    fi

    if [[ $($yaml_parser "$yaml_file" leds.internal.pins.usb) != "null" ]]
    then
        port=$($yaml_parser "$yaml_file" leds.internal.pins.usb.rx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.usb.rx.index)

        {
            printf "%s\n" "#define LED_MIDI_IN_USB_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_IN_USB_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.internal.pins.usb.tx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.usb.tx.index)

        {
            printf "%s\n" "#define LED_MIDI_OUT_USB_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_OUT_USB_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"
    fi

    if [[ $($yaml_parser "$yaml_file" leds.internal.pins.ble) != "null" ]]
    then
        port=$($yaml_parser "$yaml_file" leds.internal.pins.ble.rx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.ble.rx.index)

        {
            printf "%s\n" "#define LED_MIDI_IN_BLE_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_IN_BLE_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"

        port=$($yaml_parser "$yaml_file" leds.internal.pins.ble.tx.port)
        index=$($yaml_parser "$yaml_file" leds.internal.pins.ble.tx.index)

        {
            printf "%s\n" "#define LED_MIDI_OUT_BLE_PORT CORE_MCU_IO_PIN_PORT_DEF(${port})"
            printf "%s\n" "#define LED_MIDI_OUT_BLE_PIN CORE_MCU_IO_PIN_INDEX_DEF(${index})"
        } >> "$out_header"
    fi
fi