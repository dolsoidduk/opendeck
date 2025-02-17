/*

Copyright 2015-2022 Igor Petrovic

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

#include "board/Board.h"
#include "board/Internal.h"
#include "core/src/Timing.h"
#include "core/src/MCU.h"

namespace core::timing::detail
{
    /// Implementation of core variable used to keep track of run time in milliseconds.
    volatile uint32_t ms;
}    // namespace core::timing::detail

namespace
{
    constexpr uint32_t MAIN_TIMER_TIMEOUT_US = 1000;
#ifdef FW_APP
#if defined(BOARD_USE_FAST_SOFT_PWM_TIMER) && defined(HW_SUPPORT_SOFT_PWM)
    constexpr uint32_t SOFT_PWM_TIMER_TIMEOUT_US = 200;
#endif
#endif

    bool _usbInitialized;
}    // namespace

namespace Board
{
    void init()
    {
#if defined(FW_APP)
        detail::setup::application();

        size_t mainTimerIndex = 0;

        core::mcu::timers::allocate(mainTimerIndex, []()
                                    {
                                        core::timing::detail::ms++;
                                        detail::IO::indicators::update();
#ifndef HW_USB_OVER_SERIAL_HOST
                                        detail::IO::digitalIn::update();
#ifndef BOARD_USE_FAST_SOFT_PWM_TIMER
#if HW_MAX_NR_OF_DIGITAL_OUTPUTS > 0
                                        detail::IO::digitalOut::update();
#endif
#endif
#endif
                                    });

        core::mcu::timers::setPeriod(mainTimerIndex, MAIN_TIMER_TIMEOUT_US);
        core::mcu::timers::start(mainTimerIndex);

#if defined(BOARD_USE_FAST_SOFT_PWM_TIMER) && defined(HW_SUPPORT_SOFT_PWM)
        size_t pwmTimerIndex = 0;

        core::mcu::timers::allocate(pwmTimerIndex, []()
                                    {
#ifdef FW_APP
#ifndef HW_USB_OVER_SERIAL_HOST
#if HW_MAX_NR_OF_DIGITAL_OUTPUTS > 0
                                        detail::IO::digitalOut::update();
#endif
#endif
#endif
                                    });

        core::mcu::timers::setPeriod(pwmTimerIndex, SOFT_PWM_TIMER_TIMEOUT_US);
        core::mcu::timers::start(pwmTimerIndex);
#endif
#elif defined(FW_BOOT)
        detail::setup::bootloader();

        size_t mainTimerIndex = 0;

        core::mcu::timers::allocate(mainTimerIndex, []()
                                    {
                                        core::timing::detail::ms++;
                                        detail::IO::indicators::update();
                                    });

        // don't start the timers yet - if the app will be run immediately, it's not needed
        core::mcu::timers::setPeriod(mainTimerIndex, MAIN_TIMER_TIMEOUT_US);
#endif
    }

    namespace USB
    {
        initStatus_t init()
        {
            // allow usb init only once
            if (!_usbInitialized)
            {
                detail::USB::init();
                _usbInitialized = true;

                return initStatus_t::OK;
            }

            return initStatus_t::ALREADY_INIT;
        }
    }    // namespace USB

    namespace detail::setup
    {
        void bootloader()
        {
            // partial initialization - init the rest in runBootloader() if it's determined that bootloader should really run

            core::mcu::init(core::mcu::initType_t::BOOT);
            core::mcu::timers::init();
            detail::IO::init();

#ifdef HW_USB_OVER_SERIAL
            Board::UART::config_t config(Board::detail::USB::USB_OVER_SERIAL_BAUDRATE,
                                         Board::UART::parity_t::NO,
                                         Board::UART::stopBits_t::ONE,
                                         Board::UART::type_t::RX_TX);

            Board::UART::init(HW_UART_CHANNEL_USB_LINK, config);
#endif
        }

        void application()
        {
            core::mcu::init(core::mcu::initType_t::APP);
            core::mcu::timers::init();
            detail::IO::init();
            detail::IO::indicators::indicateApplicationLoad();

#ifdef HW_USB_OVER_SERIAL
            Board::UART::config_t config(Board::detail::USB::USB_OVER_SERIAL_BAUDRATE,
                                         Board::UART::parity_t::NO,
                                         Board::UART::stopBits_t::ONE,
                                         Board::UART::type_t::RX_TX);

            Board::UART::init(HW_UART_CHANNEL_USB_LINK, config);
#endif

#ifdef HW_USB_OVER_SERIAL_DEVICE
            // wait for unique id from usb host
            // this is to make sure host and the device share the same unique id
            USBLink::internalCMD_t cmd;

            while (1)
            {
                while (!detail::USB::readInternal(cmd))
                {
                    ;
                }

                if (cmd == USBLink::internalCMD_t::UNIQUE_ID)
                {
                    break;
                }
            }
#endif
        }
    }    // namespace detail::setup
}    // namespace Board
