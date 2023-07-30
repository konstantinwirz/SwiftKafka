#pragma once

#ifdef __APPLE__
#include "/opt/homebrew/include/librdkafka/rdkafka.h"
#else
#include "rdkafka.h"
#endif
