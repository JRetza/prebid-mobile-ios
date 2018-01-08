/*   Copyright 2017 Prebid.org, Inc.

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

#import <XCTest/XCTest.h>
#import "PBServerAdapter.h"

static NSString *const kPrebidMobileVersion = @"0.1.1";

@interface PBServerAdapter (Testing)

- (NSURLRequest *)buildRequestForAdUnits:(NSArray<PBAdUnit *> *)adUnits;
- (NSDictionary *)requestBodyForAdUnits:(NSArray<PBAdUnit *> *)adUnits;

@end

@interface PBServerAdapterTests : XCTestCase

@end

@implementation PBServerAdapterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRequestBodyForAdUnit {
    PBAdUnit *adUnit = [[PBAdUnit alloc] initWithIdentifier:@"test_identifier" andAdType:PBAdUnitTypeBanner andConfigId:@"test_config_id"];
    [adUnit addSize:CGSizeMake(250, 300)];
    NSArray *adUnits = @[adUnit];

    PBServerAdapter *serverAdapter = [[PBServerAdapter alloc] initWithAccountId:@"test_account_id"];

    NSDictionary *requestBody = [serverAdapter requestBodyForAdUnits:adUnits];

    XCTAssertEqualObjects(requestBody[@"account_id"], @"test_account_id");
    XCTAssertEqualObjects(requestBody[@"max_key_length"], @(20));
    XCTAssertEqualObjects(requestBody[@"sort_bids"], @(1));
    XCTAssertEqualObjects(requestBody[@"cache_markup"], @(1));

    NSDictionary *app = requestBody[@"app"];
    XCTAssertEqualObjects(app[@"ver"], kPrebidMobileVersion);

    NSDictionary *sdk = requestBody[@"sdk"];
    XCTAssertEqualObjects(sdk[@"version"], kPrebidMobileVersion);
    XCTAssertEqualObjects(sdk[@"platform"], @"iOS");
    XCTAssertEqualObjects(sdk[@"source"], @"prebid-mobile");

    NSDictionary *device = requestBody[@"device"];
    XCTAssertEqualObjects(device[@"os"], @"iOS");
    XCTAssertEqualObjects(device[@"make"], @"Apple");

    NSArray *requestAdUnits = requestBody[@"ad_units"];
    NSDictionary *jsonAdUnit = (NSDictionary *)[requestAdUnits firstObject];
    XCTAssertEqualObjects(jsonAdUnit[@"config_id"], @"test_config_id");
    XCTAssertEqualObjects(jsonAdUnit[@"code"], @"test_identifier");
    NSArray *sizesArray = jsonAdUnit[@"sizes"];
    XCTAssertTrue([sizesArray count] == 1);
}

- (void)testRequestBodyForAdUnitPrimaryAdServerUnknown {
    PBAdUnit *adUnit = [[PBAdUnit alloc] initWithIdentifier:@"test_identifier" andAdType:PBAdUnitTypeBanner andConfigId:@"test_config_id"];
    [adUnit addSize:CGSizeMake(250, 300)];
    NSArray *adUnits = @[adUnit];

    PBServerAdapter *serverAdapter = [[PBServerAdapter alloc] initWithAccountId:@"test_account_id"];
    serverAdapter.primaryAdServer = PBPrimaryAdServerUnknown;
    NSDictionary *requestBody = [serverAdapter requestBodyForAdUnits:adUnits];

    XCTAssertEqualObjects(requestBody[@"cache_markup"], @(1));
}

- (void)testRequestBodyForAdUnitWithDFPAdServer {
    PBAdUnit *adUnit = [[PBAdUnit alloc] initWithIdentifier:@"test_identifier" andAdType:PBAdUnitTypeBanner andConfigId:@"test_config_id"];
    [adUnit addSize:CGSizeMake(250, 300)];
    NSArray *adUnits = @[adUnit];

    PBServerAdapter *serverAdapter = [[PBServerAdapter alloc] initWithAccountId:@"test_account_id"];
    serverAdapter.primaryAdServer = PBPrimaryAdServerDFP;
    NSDictionary *requestBody = [serverAdapter requestBodyForAdUnits:adUnits];

    XCTAssertNil(requestBody[@"cache_markup"]);
}

- (void)testRequestBodyForAdUnitWithMoPubAdServer {
    PBAdUnit *adUnit = [[PBAdUnit alloc] initWithIdentifier:@"test_identifier" andAdType:PBAdUnitTypeBanner andConfigId:@"test_config_id"];
    [adUnit addSize:CGSizeMake(250, 300)];
    NSArray *adUnits = @[adUnit];

    PBServerAdapter *serverAdapter = [[PBServerAdapter alloc] initWithAccountId:@"test_account_id"];
    serverAdapter.primaryAdServer = PBPrimaryAdServerMoPub;
    NSDictionary *requestBody = [serverAdapter requestBodyForAdUnits:adUnits];

    XCTAssertEqualObjects(requestBody[@"cache_markup"], @(1));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
