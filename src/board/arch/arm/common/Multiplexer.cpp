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
#include <Target.h>

#ifdef NUMBER_OF_MUX

namespace Board
{
    namespace detail
    {
        namespace io
        {
            void dischargeMux()
            {
                // discharge the voltage present on common mux pins to avoid channel crosstalk
                for (int i = 0; i < MAX_ADC_CHANNELS; i++)
                {
                    core::io::mcuPin_t pin = Board::detail::map::adcPin(i);

                    CORE_IO_CONFIG({ CORE_IO_MCU_PIN_VAR_PORT_GET(pin), CORE_IO_MCU_PIN_VAR_PIN_GET(pin), core::io::pinMode_t::outputPP });
                    CORE_IO_SET_LOW(CORE_IO_MCU_PIN_VAR_PORT_GET(pin), CORE_IO_MCU_PIN_VAR_PIN_GET(pin));
                }
            }

            void restoreMux(uint8_t muxIndex)
            {
                core::io::mcuPin_t pin = detail::map::adcPin(muxIndex);
                CORE_IO_CONFIG({ CORE_IO_MCU_PIN_VAR_PORT_GET(pin), CORE_IO_MCU_PIN_VAR_PIN_GET(pin), core::io::pinMode_t::analog });
            }
        }    // namespace io
    }        // namespace detail
}    // namespace Board

#endif
