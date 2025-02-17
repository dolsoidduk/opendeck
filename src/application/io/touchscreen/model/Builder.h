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

#include "io/touchscreen/Touchscreen.h"

#ifdef HW_SUPPORT_TOUCHSCREEN

#include "nextion/Nextion.h"
#include "viewtech/Viewtech.h"

namespace IO
{
    class TouchscreenModelBuilder
    {
        public:
        TouchscreenModelBuilder(Touchscreen::HWA& hwa);

        private:
        Nextion  _nextion;
        Viewtech _viewtech;
    };
}    // namespace IO
#else
#include "stub/Builder.h"
#endif