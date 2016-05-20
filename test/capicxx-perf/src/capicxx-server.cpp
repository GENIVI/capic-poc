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
#include <thread>
#include <CommonAPI/CommonAPI.hpp>

#include "v0/org/genivi/capic/TestPerfStubDefault.hpp"

using namespace v0::org::genivi::capic;


class TestPerfStubImpl : public TestPerfStubDefault
{
public:
    TestPerfStubImpl() {}
    virtual ~TestPerfStubImpl();
    virtual void takeNoArgs(
        const std::shared_ptr<CommonAPI::ClientId> _client,
        takeNoArgsReply_t _reply);
    virtual void take40ByteArgs(
        const std::shared_ptr<CommonAPI::ClientId> _client, int32_t _in1,
        double _in2, double _in3, double _in41, double _in42, uint32_t _in43,
        take40ByteArgsReply_t _reply);
};

TestPerfStubImpl::~TestPerfStubImpl()
{
}

void TestPerfStubImpl::takeNoArgs(
    const std::shared_ptr<CommonAPI::ClientId> _client,
    takeNoArgsReply_t _reply)
{
    (void) _client;
    _reply();
}

void TestPerfStubImpl::take40ByteArgs(
    const std::shared_ptr<CommonAPI::ClientId> _client, int32_t _in1,
    double _in2, double _in3, double _in41, double _in42, uint32_t _in43,
    take40ByteArgsReply_t _reply)
{
    (void) _client;
    _reply(_in1, _in2, _in3, _in41, _in42, _in43);
}


int main(int argc, char* argv[]) {
    const std::chrono::seconds heartbeat(1200);

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    std::shared_ptr<TestPerfStubImpl> service = std::make_shared<TestPerfStubImpl>();
    if (!runtime->registerService(
            "local", "instance", service, "org.genivi.capic.TestPerf_instance"))
    {
        std::cout << "unable to register service" << std::endl;
        return EXIT_FAILURE;
    }

    std::cout << "Started " << argv[0] << std::endl;

    for (;;) {
        std::cout << argv[0] << " heartbeat " << heartbeat.count() << "s..."
                  << std::endl;
        std::this_thread::sleep_for(heartbeat);
    }

    std::cout << "exiting " << argv[0] << std::endl;

    return EXIT_SUCCESS;
}
