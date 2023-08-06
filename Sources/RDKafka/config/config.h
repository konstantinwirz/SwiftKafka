#ifndef _CONFIG_H_
#define _CONFIG_H_

#ifdef __APPLE__
#include "./platform/darwin.h"
#elif __linux__
#include "./platform/linux.h"
#else
#error "Unsupported platform"
#endif

#endif /* _CONFIG_H_ */
