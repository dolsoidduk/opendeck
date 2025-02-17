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

#pragma once

#include "Database.h"
#include "io/buttons/Buttons.h"
#include "io/encoders/Encoders.h"
#include "io/analog/Analog.h"
#include "io/leds/LEDs.h"
#include "io/i2c/peripherals/display/Display.h"
#include "io/touchscreen/Touchscreen.h"
#include "protocol/dmx/DMX.h"
#include "protocol/midi/MIDI.h"

namespace Database
{
    class AppLayout : public Database::Admin::Layout
    {
        public:
        AppLayout() = default;

        std::vector<LESSDB::Block>& layout(type_t type) override
        {
            switch (type)
            {
            case type_t::SYSTEM:
                return _systemLayout;

            default:
                return _userLayout;
            }
        }

        private:
        // not user accessible
        std::vector<LESSDB::Section> _systemSections = {
            // uid section
            {
                1,
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // presets
            {
                static_cast<uint8_t>(Database::Config::presetSetting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Section> _globalSections = {
            // midi settings section
            {
                static_cast<uint8_t>(Protocol::MIDI::setting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // dmx section
            {
                static_cast<uint8_t>(Protocol::DMX::setting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Section> _buttonSections = {
            // type section
            {
                IO::Buttons::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // message type section
            {
                IO::Buttons::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // midi id section
            {
                IO::Buttons::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // value section
            {
                IO::Buttons::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                127,
            },

            // channel section
            {
                IO::Buttons::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                1,
            },
        };

        std::vector<LESSDB::Section> _encoderSections = {
            // encoder enabled section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // encoder inverted section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // encoding mode section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // midi id section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::ENABLE,
                0,
            },

            // channel section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                1,
            },

            // pulses per step section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                4,
            },

            // acceleration section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // remote sync section
            {
                IO::Encoders::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Section> _analogSections = {
            // analog enabled section
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // analog inverted section
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // analog type section
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // midi id section
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::ENABLE,
                0,
            },

            // lower value limit
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // upper value limit
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                16383,
            },

            // channel section
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                1,
            },

            // lower adc percentage offset
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // upper adc percentage offset
            {
                IO::Analog::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Section> _ledSections = {
            // global parameters section
            {
                static_cast<size_t>(IO::LEDs::setting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // activation id section
            {
                IO::LEDs::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // rgb enabled section
            {
                (IO::LEDs::Collection::size() / 3) + (IO::Touchscreen::Collection::size() / 3),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // led control type section
            {
                IO::LEDs::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // single velocity value section
            {
                IO::LEDs::Collection::size(),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                127,
            },

            // channel section
            {
                IO::LEDs::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                1,
            },
        };

        std::vector<LESSDB::Section> _i2cSections = {
            // display section
            {
                static_cast<uint8_t>(IO::Display::setting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Section> _touchscreenSections = {
            // setting section
            {
                static_cast<uint8_t>(IO::Touchscreen::setting_t::AMOUNT),
                LESSDB::sectionParameterType_t::BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // x position section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // y position section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // width section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // height section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::WORD,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // on screen section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // off screen section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // page switch enabled section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::BIT,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },

            // page switch index section
            {
                IO::Touchscreen::Collection::size(),
                LESSDB::sectionParameterType_t::HALF_BYTE,
                LESSDB::preserveSetting_t::DISABLE,
                LESSDB::autoIncrementSetting_t::DISABLE,
                0,
            },
        };

        std::vector<LESSDB::Block> _systemLayout = {
            // system block
            {
                _systemSections,
            },
        };

        std::vector<LESSDB::Block> _userLayout = {
            // global block
            {
                _globalSections,
            },

            // buttons block
            {
                _buttonSections,
            },

            // encoder block
            {
                _encoderSections,
            },

            // analog block
            {
                _analogSections,
            },

            // led block
            {
                _ledSections,
            },

            // display block
            {
                _i2cSections,
            },

            // touchscreen block
            {
                _touchscreenSections,
            },
        };
    };
}    // namespace Database