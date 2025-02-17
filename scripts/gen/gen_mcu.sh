#!/usr/bin/env bash

# core module already provides defines and Makefile for MCU via
# its own gen_mcu.sh script.
# This script is used to provide additional project-specific
# configuration on top of base configuration.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
base_yaml_file=$1
yaml_file=$2
gen_dir=$3
extFreq=$4
yaml_parser="dasel -n -p yaml --plain -f"
out_header="$gen_dir"/MCU.h
out_makefile="$gen_dir"/MCU.mk

if ! "$script_dir"/../../modules/core/scripts/gen_mcu.sh "$base_yaml_file" "$gen_dir" "$extFreq"
then
    exit 1
fi

echo "Generating MCU configuration..."

printf "%s\n" "### OPENDECK ADDITIONS ###" >> "$out_makefile"

mkdir -p "$gen_dir"

app_start_page=$($yaml_parser "$yaml_file" flash.app-start-page)
boot_start_page=$($yaml_parser "$yaml_file" flash.boot-start-page)
app_boot_jump_offset=$($yaml_parser "$yaml_file" flash.app-boot-jump-offset)
adc_prescaler=$($yaml_parser "$yaml_file" adc.prescaler)
adc_samples=$($yaml_parser "$yaml_file" adc.samples)

if [[ $app_start_page == "null" ]]
then
    app_start_page=0
fi

if [[ $boot_start_page != "null" ]]
then
    {
        printf "%s\n" "DEFINES += HW_SUPPORT_BOOTLOADER"
    } >> "$out_makefile"
else
    # No bootloader, start at first page
    app_start_page=0
fi

{
    printf "%s\n" "DEFINES += FLASH_PAGE_APP=$app_start_page"
} >> "$out_makefile"

if [[ $($yaml_parser "$base_yaml_file" flash.pages) != "null" ]]
then
    app_start_address=$($yaml_parser "$base_yaml_file" flash.pages.["$app_start_page"].address)

    if [[ $boot_start_page != "null" ]]
    then
        boot_start_address=$($yaml_parser "$base_yaml_file" flash.pages.["$boot_start_page"].address)
    fi
else
    # All flash pages have common size
    app_start_address=$($yaml_parser "$base_yaml_file" flash.page-size)
    flash_start_address=$($yaml_parser "$base_yaml_file" flash.flash-start)
    ((app_start_address*=app_start_page))
    ((app_start_address+=flash_start_address))

    if [[ $boot_start_page != "null" ]]
    then
        boot_start_address=$($yaml_parser "$base_yaml_file" flash.page-size)
        ((boot_start_address*=boot_start_page))
        ((boot_start_address+=flash_start_address))
    fi
fi

{
    printf "%s%x\n" "FLASH_ADDR_APP_START := 0x" "$app_start_address"
    printf "%s\n" 'FLASH_ADDR_FW_METADATA := $(shell printf "0x%x" $$(( $(FLASH_ADDR_APP_START) + $(CORE_FW_METADATA_OFFSET) )) )'
} >> "$out_makefile"

if [[ $boot_start_page != "null" ]]
then
    {
        printf "%s%x\n" "FLASH_ADDR_BOOT_START := 0x" "$boot_start_address"
    } >> "$out_makefile"
fi

if [[ $($yaml_parser "$yaml_file" flash.emueeprom) != "null" ]]
then
    factory_flash_page=$($yaml_parser "$yaml_file"  flash.emueeprom.factory-page.page)
    factory_flash_page_offset=$($yaml_parser "$yaml_file" flash.emueeprom.factory-page.start-offset)
    eeprom_flash_page_1=$($yaml_parser "$yaml_file" flash.emueeprom.page1.page)
    eeprom_flash_page_2=$($yaml_parser "$yaml_file" flash.emueeprom.page2.page)

    if [[ $factory_flash_page_offset == "null" ]]
    then
        factory_flash_page_offset=0
    fi

    {
        printf "%s\n" "FLASH_PAGE_FACTORY := $factory_flash_page"
        printf "%s\n" "FLASH_PAGE_EEPROM_1 := $eeprom_flash_page_1"
        printf "%s\n" "FLASH_PAGE_EEPROM_2 := $eeprom_flash_page_2"
        printf "%s\n" 'DEFINES += FLASH_PAGE_FACTORY=$(FLASH_PAGE_FACTORY)'
        printf "%s\n" 'DEFINES += FLASH_PAGE_EEPROM_1=$(FLASH_PAGE_EEPROM_1)'
        printf "%s\n" 'DEFINES += FLASH_PAGE_EEPROM_2=$(FLASH_PAGE_EEPROM_2)'
    } >> "$out_makefile"

    if [[ $($yaml_parser "$base_yaml_file" flash.pages) == "null" ]]
    then
        # Common flash page size
        {
            printf "%s\n" 'EMU_EEPROM_PAGE_SIZE := $(shell echo $$(( ($(FLASH_PAGE_EEPROM_2) - $(FLASH_PAGE_EEPROM_1)) * $(CORE_MCU_FLASH_PAGE_SIZE_COMMON) )) )'
            printf "%s\n" 'DEFINES += EMU_EEPROM_PAGE_SIZE=$(EMU_EEPROM_PAGE_SIZE)'
            # Offset is never used when flash pages have the same size
            printf "%s\n" 'EMU_EEPROM_FLASH_USAGE := $(shell echo $$(( $(EMU_EEPROM_PAGE_SIZE) * 3 )) )'
        } >> "$out_makefile"
    else
        emueeprom_factory_size=$($yaml_parser "$base_yaml_file" flash.pages.["$factory_flash_page"].size)
        emueeprom_page1_size=$($yaml_parser "$base_yaml_file" flash.pages.["$eeprom_flash_page_1"].size)
        emueeprom_page2_size=$($yaml_parser "$base_yaml_file" flash.pages.["$eeprom_flash_page_2"].size)

        emueeprom_page_size=$emueeprom_factory_size
        ((emueeprom_page_size-=factory_flash_page_offset))
        emueeprom_flash_usage=$((emueeprom_page_size + emueeprom_page1_size + emueeprom_page2_size))

        {
            printf "%s\n" "EMU_EEPROM_PAGE_SIZE := $emueeprom_page_size"
            printf "%s\n" 'DEFINES += EMU_EEPROM_PAGE_SIZE=$(EMU_EEPROM_PAGE_SIZE)'
            printf "%s\n" "EMU_EEPROM_FLASH_USAGE := $emueeprom_flash_usage"
        } >> "$out_makefile"
    fi

    # When emulated EEPROM is used, one of the pages is factory page with
    # default settings. Database shouldn't be formatted in this case.
    # The values from factory page should be used as initial ones.
    printf "%s\n" "DEFINES += DATABASE_INIT_DATA=0" >> "$out_makefile"
else
    printf "%s\n" "DEFINES += DATABASE_INIT_DATA=1" >> "$out_makefile"
fi

if [[ $app_boot_jump_offset != "null" ]]
then
    printf "%s\n" "DEFINES += FLASH_OFFSET_APP_JUMP_FROM_BOOTLOADER=$app_boot_jump_offset" >> "$out_makefile"
fi

if [[ $($yaml_parser "$yaml_file" fuses) != "null" ]]
then
    fuse_unlock=$($yaml_parser "$yaml_file" fuses.unlock)
    fuse_lock=$($yaml_parser "$yaml_file" fuses.lock)
    fuse_ext=$($yaml_parser "$yaml_file" fuses.ext)
    fuse_high=$($yaml_parser "$yaml_file" fuses.high)
    fuse_low=$($yaml_parser "$yaml_file" fuses.low)

    {
        printf "%s\n" "FUSE_UNLOCK := $fuse_unlock"
        printf "%s\n" "FUSE_LOCK := $fuse_lock"
        printf "%s\n" "FUSE_EXT := $fuse_ext"
        printf "%s\n" "FUSE_HIGH := $fuse_high"
        printf "%s\n" "FUSE_LOW := $fuse_low"
    } >> "$out_makefile"
fi

if [[ $adc_prescaler != "null" ]]
then
    printf "%s\n" "DEFINES += HW_ADC_PRESCALER=$adc_prescaler" >> "$out_makefile"
fi

if [[ $adc_samples != "null" ]]
then
    printf "%s\n" "DEFINES += HW_ADC_SAMPLES=$adc_samples" >> "$out_makefile"
fi