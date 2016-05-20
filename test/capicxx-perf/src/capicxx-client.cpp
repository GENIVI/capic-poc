/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2016, Visteon Corp.
 * Author: Pavel Konopelko, pkonopel@visteon.com
 *
 * This file is part of Common API C
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License (MPL), version 2.0.
 * If a copy of the MPL was not distributed with this file,
 * you can obtain one at http://mozilla.org/MPL/2.0/.
 * For further information see http://www.genivi.org/.
 */

#include <iostream>
#include <string>
#include <cstdlib>
#include <unistd.h>
#include <time.h>
#include <CommonAPI/CommonAPI.hpp>

#include "v0/org/genivi/capic/TestPerfProxy.hpp"

using namespace v0::org::genivi::capic;


static int32_t in1 = 12;
static double in2 = 34.0, in3 = 0.56;
static double in41 = 0.78, in42 = 91.0;
static uint32_t in43 = 1112;

static int32_t out1;
static double out2, out3;
static double out41, out42;
static uint32_t out43;


int main(int argc, char* argv[])
{
    int message_count = 10000, message_payload = 0;
    int option = 0;
    struct timespec start, stop;
    double seconds;

    while ((option = getopt(argc, argv, "m:p")) != -1) {
        switch (option) {
        case 'm':
            message_count = atoi(optarg);
            break;
        case 'p':
            message_payload = 1;
            break;
        default:
            printf("Usage: %s [-m count] [-p]\n", argv[0]);
            printf("-m count  send count messages\n");
            printf("-p        send messages with payload\n");
            return EXIT_FAILURE;
        }
    }

    std::cout << "Started " << argv[0] << std::endl;

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    std::shared_ptr<TestPerfProxy<>> proxy = runtime->buildProxy<TestPerfProxy>(
        "local", "instance", "org.genivi.capic.TestPerf_instance");
    if (!proxy) {
        std::cout << "unable to create proxy" << std::endl;
        return EXIT_FAILURE;
    }

    //FIXME: how to check whether the proxy is available?

    while (!proxy->isAvailable())
        usleep(10);

    std::cout << "starting test..." << std::endl;
    clock_gettime(CLOCK_REALTIME, &start);

    if (message_payload) {
        for (int counter = message_count; counter > 0; --counter) {
            CommonAPI::CallStatus callStatus;
            proxy->take40ByteArgs(
                in1, in2, in3, in41, in42, in43, callStatus,
                out1, out2, out3, out41, out42, out43);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cout << "Unable to call take40ByteArgs() ("
                          << int(callStatus) << ")" << std::endl;
                return EXIT_FAILURE;
            }
            in1 = out1;
            in2 = out2;
            in3 = out3;
            in41 = out41;
            in42 = out42;
            in43 = out43;
        }
    } else {
        for (int counter = message_count; counter > 0; --counter) {
            CommonAPI::CallStatus callStatus;
            proxy->takeNoArgs(callStatus);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cout << "Unable to call takeNoArgs() ("
                          << int(callStatus) << ")" << std::endl;
                return EXIT_FAILURE;
            }
        }
    }

    clock_gettime(CLOCK_REALTIME, &stop);
    seconds = stop.tv_sec - start.tv_sec + (stop.tv_nsec - start.tv_nsec) / 1.0e+9;
    std::cout << "test completed" << std::endl;
    std::cout << "message payload [bytes]: " << (message_payload ? 40 : 0) << std::endl;
    std::cout << "sync messages sent:      " << message_count << std::endl;
    std::cout << "messages per [s]:        " << message_count / seconds << std::endl;

    std::cout << "exiting " << argv[0] << std::endl;

    return EXIT_SUCCESS;
}
