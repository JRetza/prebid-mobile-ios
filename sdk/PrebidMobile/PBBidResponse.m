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

#import "PBBidResponse.h"

@interface PBBidResponse ()

@property (nonatomic, assign) NSTimeInterval createdTime;
@property (nonatomic, readwrite) NSMutableDictionary<NSString *, NSString *> *__nullable customKeywords;

@end

static NSTimeInterval const kDefaultBidExpiryTime = 270;


@implementation PBBidResponse

#pragma mark Class Methods

+ (nonnull instancetype)bidResponseWithAdUnitId:(nonnull NSString *)adUnitId
                              adServerTargeting:(nonnull NSDictionary<NSString *,NSString *> *)adServerTargeting {
    PBBidResponse *newBidResponse = [[PBBidResponse alloc] initWithAdUnitId:adUnitId
                                                          adServerTargeting:adServerTargeting];
    return (newBidResponse);
}

+ (nonnull instancetype)bidResponseWithAdUnitId2:(nonnull NSString *)adUnitId
                              adServerTargeting:(nonnull NSDictionary<NSString *,NSString *> *)adServerTargeting
                                          bidder:(nonnull NSString *)bidder
                                           price:(double) price
                                           width:(long) width
                                          height:(long)height
                                    responseTime:(long) responseTime
                                         cacheId:(nonnull NSString *)cacheId

{
    PBBidResponse *newBidResponse = [[PBBidResponse alloc] initWithAdUnitId:adUnitId
                                                          adServerTargeting:adServerTargeting
                                                                     bidder:bidder
                                                                      price:price
                                                                      width:width
                                                                     height:height
                                                               responseTime:responseTime
                                                                    cacheId:cacheId
                                     ];
    return (newBidResponse);
}

#pragma mark Instance Methods

- (nonnull instancetype)initWithAdUnitId:(nonnull NSString *)adUnitId
                       adServerTargeting:(nonnull NSDictionary<NSString *,NSString *> *)adServerTargeting {
    if ((self = [super init])) {
        _adUnitId = [adUnitId copy];
        _customKeywords = [adServerTargeting copy];

        // Setting the default bid expiration time to be 4 minutes 30 seconds
        _timeToExpireAfter = kDefaultBidExpiryTime;
        _createdTime = [[NSDate date] timeIntervalSince1970];
    }

    return (self);
}

- (nonnull instancetype)initWithAdUnitId:(nonnull NSString *)adUnitId
                       adServerTargeting:(nonnull NSDictionary<NSString *,NSString *> *)adServerTargeting
                                  bidder:(nonnull NSString *)bidder
                                   price:(double) price
                                   width:(long) width
                                  height:(long)height
                            responseTime:(long) responseTime
                                 cacheId:(nonnull NSString *)cacheId
{
    if ((self = [super init])) {
        _adUnitId = [adUnitId copy];
        _customKeywords = [adServerTargeting copy];
        _bidder = [bidder copy];
        _price = price;
        //_price = drand48()*5;
        _width = width;
        _height = height;
        _responseTime = responseTime;
        _cacheId = cacheId;
        _responseType = 1;
        
        // Setting the default bid expiration time to be 4 minutes 30 seconds
        _timeToExpireAfter = kDefaultBidExpiryTime;
        _createdTime = [[NSDate date] timeIntervalSince1970];
    }
    
    return (self);
}

- (void)addCustomKeywordWithKey:(NSString *)key value:(NSString *)value {
    if (_customKeywords == nil) {
        _customKeywords = [[NSMutableDictionary alloc] init];
    }
    [_customKeywords setObject:value forKey:key];
}

- (BOOL)isExpired {
    return ([[NSDate date] timeIntervalSince1970] - self.createdTime > self.timeToExpireAfter);
}

@end
