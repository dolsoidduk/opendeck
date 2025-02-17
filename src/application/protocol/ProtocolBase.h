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

#include <inttypes.h>

namespace Protocol
{
    enum class protocol_t : uint8_t
    {
        MIDI,
        DMX,
        AMOUNT
    };

    class Base
    {
        public:
        virtual bool init()   = 0;
        virtual bool deInit() = 0;
        virtual void read()   = 0;
    };
}    // namespace Protocol
