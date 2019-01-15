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

#import "NSObject+Prebid.h"
#import "NSString+Extension.h"
#import "NSTimer+Extension.h"
#import "PBBidManager.h"
#import "PBBidResponse.h"
#import "PBBidResponseDelegate.h"
#import "PBException.h"
#import "PBKeywordsManager.h"
#import "PBLogging.h"
#import "PBServerAdapter.h"
#include <math.h>

static NSTimeInterval const kBidExpiryTimerInterval = 30;

@interface PBBidManager ()

@property id<PBBidResponseDelegate> delegate;
- (void)saveBidResponses:(nonnull NSArray<PBBidResponse *> *)bidResponse;

@property (nonnull) NSString* accountId;
@property (nonnull) NSString* appName;
@property (nonatomic) NSString* appPage;

@property (nonatomic, assign) NSTimeInterval topBidExpiryTime;
@property (nonatomic, strong) PBServerAdapter *demandAdapter;

@property (nonatomic, strong) NSMutableSet<PBAdUnit *> *adUnits;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray<PBBidResponse *> *> *__nullable bidsMap;

@property (nonatomic) long long lastGatherStats;


@property (nonatomic, assign) PBPrimaryAdServerType adServer;


@end

#pragma mark PBBidResponseDelegate Implementation

@interface PBBidResponseDelegateImplementation : NSObject <PBBidResponseDelegate>

@end

@implementation PBBidResponseDelegateImplementation

- (void)didReceiveSuccessResponse:(nonnull NSArray<PBBidResponse *> *)bids {
    
    [[PBBidManager sharedInstance] saveBidResponses:bids];
}

- (void)didCompleteWithError:(nonnull NSError *)error {
    if (error) {
        PBLogDebug(@"Bid Failure: %@", [error localizedDescription]);
    }
}

@end

@implementation PBBidManager

@synthesize delegate;

static PBBidManager *sharedInstance = nil;
static dispatch_once_t onceToken;

#pragma mark Public API Methods

+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        
        [sharedInstance setDelegate:[[PBBidResponseDelegateImplementation alloc] init]];
    });
    return sharedInstance;
}

+ (void)resetSharedInstance {
    onceToken = 0;
    sharedInstance = nil;
}
- (void)registerAdUnits:(nonnull NSArray<PBAdUnit *> *)adUnits
          withAccountId:(nonnull NSString *)accountId
               withHost:(PBServerHost)host
     andPrimaryAdServer:(PBPrimaryAdServerType)adServer
            withAppName:(nonnull NSString *)appName{
    if (_adUnits == nil) {
        _adUnits = [[NSMutableSet alloc] init];
    }
    _bidsMap = [[NSMutableDictionary alloc] init];
    self.accountId = accountId;
    self.appName = appName;

    self.adServer = adServer;
    self.lastGatherStats = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    _demandAdapter = [[PBServerAdapter alloc] initWithAccountId:accountId andHost:host andAdServer:adServer] ;
    
    for (id adUnit in adUnits) {
        [self registerAdUnit:adUnit];
    }
    //[self startPollingBidsExpiryTimer]; //Disable automatic pulling for new Bids
    [self requestBidsForAdUnits:adUnits];
}

- (NSMutableSet<PBAdUnit *> *) getRegisteredAdUnits {
    return self.adUnits;
}

- (nullable PBAdUnit *)adUnitByIdentifier:(nonnull NSString *)identifier {
    NSArray *adUnits = [_adUnits allObjects];
    for (PBAdUnit *adUnit in adUnits) {
        if ([[adUnit identifier] isEqualToString:identifier]) {
            return adUnit;
        }
    }
    return nil;
}

- (void)assertAdUnitRegistered:(NSString *)identifier {
    PBAdUnit *adUnit = [self adUnitByIdentifier:identifier];
    if (adUnit == nil) {
        // If there is no registered ad unit we can't complete the bidding
        // so throw an exception
        @throw [PBException exceptionWithName:PBAdUnitNotRegisteredException];
    }
}

- (nullable NSDictionary<NSString *, NSString *> *)keywordsForWinningBidForAdUnit:(nonnull PBAdUnit *)adUnit {
    NSArray *bids = [self getBids:adUnit];
    if(!bids || [bids count]==0){
        [self resetAdUnit:adUnit];
        //[self requestBidsForAdUnits:@[adUnit]];
    }
    if (bids) {
        PBLogDebug(@"Bids available to create keywords");
        NSMutableDictionary<NSString *, NSString *> *keywords = [[NSMutableDictionary alloc] init];
        //for (PBBidResponse *bidResp in bids) {
          //  [keywords addEntriesFromDictionary:bidResp.customKeywords];
        //
        NSArray * sortedBids = [bids sortedArrayUsingFunction:sortBids context:NULL];
        PBBidResponse* winner = sortedBids[0];
        if(winner != nil){
            NSString* prefix = @"pb_";
            keywords[[NSString stringWithFormat:@"%@winner", prefix]] = winner.bidder;
            long cpm = round(winner.price*1000);
            keywords[[NSString stringWithFormat:@"%@cpm", prefix]] = [NSString stringWithFormat:@"%lu", cpm];
            keywords[[NSString stringWithFormat:@"%@size", prefix]] = [NSString stringWithFormat:@"%lux%lu", winner.width, winner.height];
            if (winner.dealId != nil) {
                keywords[[NSString stringWithFormat:@"%@deal", prefix]] = winner.dealId;
            }
            keywords[@"hb_size"] = keywords[[NSString stringWithFormat:@"%@size", prefix]] ;
            keywords[@"hb_env"] = @"mobile-app";
            keywords[@"hb_cache_id"] = winner.cacheId;
            keywords[@"hb_format"] = @"html";
            
            [keywords addEntriesFromDictionary:winner.customKeywords];
        }
        for (PBBidResponse *bidResp in bids) {
            bidResp.sendToAdserver = YES;
            
        }
        
        return keywords;
    }
    PBLogDebug(@"No bid available to create keywords");
    return nil;
}

NSInteger sortBids(PBBidResponse* bidL, PBBidResponse* bidR, void *context){
    double v1 = bidL.price;
    double v2 = bidR.price;
    if (v1 > v2)
        return NSOrderedAscending;
    else if (v1 < v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


- (NSDictionary *)addPrebidParameters:(NSDictionary *)requestParameters
                         withKeywords:(NSDictionary *)keywordsPairs {
    NSDictionary *existingExtras = requestParameters[@"extras"];
    if (keywordsPairs) {
        NSMutableDictionary *mutableRequestParameters = [requestParameters mutableCopy];
        NSMutableDictionary *mutableExtras = [[NSMutableDictionary alloc] init];
        if (existingExtras) {
            mutableExtras = [existingExtras mutableCopy];
        }
        for (id key in keywordsPairs) {
            id value = [keywordsPairs objectForKey:key];
            if (value) {
                mutableExtras[key] = value;
            }
        }
        mutableRequestParameters[@"extras"] = [mutableExtras copy];
        requestParameters = [mutableRequestParameters copy];
    }
    return requestParameters;
}
- (void)attachTopBidHelperForAdUnitId:(nonnull NSString *)adUnitIdentifier
                           andTimeout:(int)timeoutInMS
                    completionHandler:(nullable void (^)(void))handler {
    [self attachTopBidHelperForAdUnitId:adUnitIdentifier andTimeout:timeoutInMS andStartTime: (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) completionHandler:handler];
}

- (void)attachTopBidHelperForAdUnitId:(nonnull NSString *)adUnitIdentifier
                           andTimeout:(int)timeoutInMS
                         andStartTime:(long long)startInMS
                    completionHandler:(nullable void (^)(void))handler {
    [self assertAdUnitRegistered:adUnitIdentifier];
    if (timeoutInMS > kPCAttachTopBidMaxTimeoutMS) {
        timeoutInMS = kPCAttachTopBidMaxTimeoutMS;
    }
    
    [self assertNoBidsSendToAdserverAndScheduleNewBidsWhenNeeded:adUnitIdentifier];
    
    
    
    if ([self isBidReady:adUnitIdentifier]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            PBLogDebug(@"Calling completionHandler on attachTopBidWhenReady isBidReady");
            handler();
        });
    } else {
        //timeoutInMS = timeoutInMS - kPCAttachTopBidTimeoutIntervalMS;
        long long currTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        NSLog(@"calling attachTopBidHelperForAdUnitId %d %lld", timeoutInMS,currTime - startInMS);
        //if (timeoutInMS > 0) {
        if(currTime - startInMS<timeoutInMS){
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * kPCAttachTopBidTimeoutIntervalMS);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                [self attachTopBidHelperForAdUnitId:adUnitIdentifier
                                         andTimeout:timeoutInMS
                                       andStartTime:startInMS
                                  completionHandler:handler];
            });
        } else {
            PBLogDebug(@"Attempting to attach cached bid for ad unit %@", adUnitIdentifier);
            PBLogDebug(@"Calling completionHandler on attachTopBidWhenReady bids not ready");
            handler();
        }
    }
}

- (void) assertNoBidsSendToAdserverAndScheduleNewBidsWhenNeeded:(nonnull NSString *)adUnitIdentifier {
    for (long i = [_bidsMap[adUnitIdentifier] count]-1; i>=0; i--){
        PBBidResponse*bid = _bidsMap[adUnitIdentifier][i];
        if(bid.sendToAdserver == YES){
            [_bidsMap[adUnitIdentifier] removeObjectAtIndex:i];
        }
    }
    if([_bidsMap[adUnitIdentifier] count] == 0){
        PBAdUnit * adUnit = [self adUnitByIdentifier:adUnitIdentifier];
        NSLog(@"checking if it's needed to request new bids : %d",adUnit.isRequesting);
        if(!adUnit.isRequesting){
            [adUnit generateUUID];
            [adUnit reset];
            //[self resetAdUnit:adUnit];
            [self requestBidsForAdUnits:@[adUnit]];
        }
    }
}

-(void) loadOnSecureConnection:(BOOL) secureConnection {
    if(self.adServer == PBPrimaryAdServerMoPub){
        self.demandAdapter.isSecure = secureConnection;
    }
}

#pragma mark Internal Methods

- (void)registerAdUnit:(PBAdUnit *)adUnit {
    // Throw exceptions if size or demand source is not specified
    if (adUnit.adSizes == nil && adUnit.adType == PBAdUnitTypeBanner) {
        @throw [PBException exceptionWithName:PBAdUnitNoSizeException];
    }
    
    // Check if ad unit already exists, if so remove it
    NSMutableArray *adUnitsToRemove = [[NSMutableArray alloc] init];
    for (PBAdUnit *existingAdUnit in _adUnits) {
        if ([existingAdUnit.identifier isEqualToString:adUnit.identifier]) {
            [adUnitsToRemove addObject:existingAdUnit];
        }
    }
    for (PBAdUnit *adUnit in adUnitsToRemove) {
        [_adUnits removeObject:adUnit];
    }
    
    // Finish registration of ad unit by adding it to adUnits
    [_adUnits addObject:adUnit];
    PBLogDebug(@"AdUnit %@ is registered with Prebid Mobile", adUnit.identifier);
}

- (void)requestBidsForAdUnits:(NSArray<PBAdUnit *> *)adUnits {
    [_demandAdapter requestBidsWithAdUnits:adUnits withDelegate:[self delegate]];
}

- (void)resetAdUnit:(PBAdUnit *)adUnit {
    [adUnit generateUUID];
    [adUnit reset];
    [_bidsMap removeObjectForKey:adUnit.identifier];
    NSLog(@"reset _bidsMap");
}

- (void)saveBidResponses:(NSArray <PBBidResponse *> *)bidResponses {
    if ([bidResponses count] > 0) {
        PBBidResponse *bid = (PBBidResponse *)bidResponses[0];
        NSLog(@"set _bidsMap");
        [_bidsMap setObject:[bidResponses mutableCopy] forKey:bid.adUnitId];
        
        // TODO: if prebid server returns expiry time for bids we need to change this implementation
        NSTimeInterval timeToExpire = bid.timeToExpireAfter + [[NSDate date] timeIntervalSince1970];
        PBAdUnit *adUnit = [self adUnitByIdentifier:bid.adUnitId];
        adUnit.isRequesting = NO;
        [adUnit setTimeIntervalToExpireAllBids:timeToExpire];
    }
}

// Poll every 30 seconds to check for expired bids
- (void)startPollingBidsExpiryTimer {
    __weak PBBidManager *weakSelf = self;
    if ([[NSTimer class] respondsToSelector:@selector(pb_scheduledTimerWithTimeInterval:block:repeats:)]) {
        [NSTimer pb_scheduledTimerWithTimeInterval:kBidExpiryTimerInterval
                                             block:^{
                                                 PBBidManager *strongSelf = weakSelf;
                                                 [strongSelf checkForBidsExpired];
                                             }
                                           repeats:YES];
    }
}

- (void)checkForBidsExpired {
    if (_adUnits != nil && _adUnits.count > 0) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSMutableArray *adUnitsToRequest = [[NSMutableArray alloc] init];
        for (PBAdUnit *adUnit in _adUnits) {
            NSMutableArray *bids = [_bidsMap objectForKey:adUnit.identifier];
            if (bids && [bids count] > 0 && [adUnit shouldExpireAllBids:currentTime]) {
                [adUnitsToRequest addObject:adUnit];
                [self resetAdUnit:adUnit];
            }
        }
        if ([adUnitsToRequest count] > 0) {
            [self requestBidsForAdUnits:adUnitsToRequest];
        }
    }
}

- (nullable NSArray<PBBidResponse *> *)getBids:(PBAdUnit *)adUnit {
    NSMutableArray *bids = [_bidsMap objectForKey:adUnit.identifier];
    if (bids && [bids count] > 0) {
        return bids;
    }
    PBLogDebug(@"Bids for adunit not available");
    return nil;
}

- (BOOL)isBidReady:(NSString *)identifier {
    if ([_bidsMap objectForKey:identifier] != nil &&
        [[_bidsMap objectForKey:identifier] count] > 0) {
        PBLogDebug(@"Bid is ready for ad unit with identifier %@", identifier);
        return YES;
    }
    return NO;
}

- (void)setBidOnAdObject:(NSObject *)adObject {
    
    
    if (adObject.pb_identifier) {
        
        [self clearBidOnAdObject:adObject];
        
        NSMutableArray *mutableKeywords;
        NSString *keywords = @"";
        SEL getKeywords = NSSelectorFromString(@"keywords");
        if ([adObject respondsToSelector:getKeywords]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            keywords = (NSString *)[adObject performSelector:getKeywords];
        }
        if (keywords.length) {
            mutableKeywords = [[keywords componentsSeparatedByString:@","] mutableCopy];
        }
        if (!mutableKeywords) {
            mutableKeywords = [[NSMutableArray alloc] init];
        }
        PBAdUnit *adUnit = adObject.pb_identifier;
        NSDictionary<NSString *, NSString *> *keywordsPairs = [self keywordsForWinningBidForAdUnit:adUnit];
        for (id key in keywordsPairs) {
            id value = [keywordsPairs objectForKey:key];
            if (value) {
                [mutableKeywords addObject:[NSString stringWithFormat:@"%@:%@", key, value]];
            }
        }
        if ([[mutableKeywords componentsJoinedByString:@","] length] > 4000) {
            PBLogDebug(@"Bid to MoPub is too long");
        } else {
            SEL setKeywords = NSSelectorFromString(@"setKeywords:");
            if ([adObject respondsToSelector:setKeywords]) {
                NSString *keywordsToSet = [mutableKeywords componentsJoinedByString:@","];
                [adObject performSelector:setKeywords withObject:keywordsToSet];
#pragma clang diagnostic pop
            }
        }
    } else {
        PBLogDebug(@"No bid available to pass to MoPub");
    }
}

///
// bids should not be cleared n set to nil as setting to nil will remove all publisher keywords too
// so just remove all bids thats related to prebid... Prebid targeting starts as "hb_"
///
- (void)clearBidOnAdObject:(NSObject *)adObject {
    NSString *keywordsString = @"";
    SEL getKeywords = NSSelectorFromString(@"keywords");
    if ([adObject respondsToSelector:getKeywords]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        keywordsString = (NSString *)[adObject performSelector:getKeywords];
    }
    if (keywordsString.length) {
        
        NSArray *keywords = [keywordsString componentsSeparatedByString:@","];
        NSMutableArray *mutableKeywords = [keywords mutableCopy];
        [keywords enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL *stop) {
            if ([keyword hasPrefix:@"hb_"]) {
                [mutableKeywords removeObject:keyword];
            }
        }];
        
        SEL setKeywords = NSSelectorFromString(@"setKeywords:");
        if ([adObject respondsToSelector:setKeywords]) {
            [adObject performSelector:setKeywords withObject:[mutableKeywords componentsJoinedByString:@","]];
#pragma clang diagnostic pop
        }
    }
}
- (void) adUnitReceivedDefault: (UIView *)adView {
    NSLog(@"adUnitReceivedDefault");
    PBAdUnit *adUnit = adView.pb_identifier;
    adUnit.isDefault = YES;
}
- (void) adUnitReceivedAppEvent: (UIView *)adView
              andWithInstruction:(NSString*)instruction
               andWithParameter:(NSString*)prm {
    if([instruction isEqualToString: @"deliveryData"]){
        NSArray* items = [prm componentsSeparatedByString:@"|"];
        NSString* lineItemId = nil;
        NSString* creativeId = nil;
        if(items.count==2){
            lineItemId = items[0];
            creativeId = items[1];
            PBAdUnit *adUnit = adView.pb_identifier;
            adUnit.lineItemId = lineItemId;
            adUnit.creativeId = creativeId;
        }
    }else if([instruction isEqualToString: @"wonHB"]){
        PBAdUnit *adUnit = adView.pb_identifier;
        for (PBBidResponse* bid in _bidsMap[adUnit.identifier]){
            if ([bid.cacheId isEqualToString:prm]) {
                bid.won = YES;
            }
        }
    }
}

- (void) markAdUnitLoaded: (UIView *)adView{
    PBAdUnit *adUnit = adView.pb_identifier;
    adUnit.stopLoadTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
}

- (void)trackStats:(NSData *)statsJson{
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://tagmans3.adsolutions.com/log/"]
                                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                   timeoutInterval:1000];
    [mutableRequest setHTTPMethod:@"POST"];
    [mutableRequest setHTTPBody:statsJson];
    
    
    [NSURLConnection sendAsynchronousRequest:mutableRequest
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSLog(@"tracked stats");
                           }];
    
}

- (void) setAppPage:(NSString *)appPage{
    _appPage = appPage;
}

- (void) gatherStats{
    NSMutableDictionary *statsDict = [[NSMutableDictionary alloc] init];
    
    int height = [UIScreen mainScreen].bounds.size.height;
    int width = [UIScreen mainScreen].bounds.size.width;
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    statsDict[@"client"] = self.accountId;
    statsDict[@"host"] = self.appName;
    statsDict[@"page"] = self.appPage;
    statsDict[@"proto"] = @"https:";
    statsDict[@"duration"] = @(0);
    statsDict[@"screenWidth"] = @(width);
    statsDict[@"screenHeight"] = @(height);
    statsDict[@"language"] = language;
    long long currTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    statsDict[@"duration"] = @(currTime - _lastGatherStats);
    statsDict[@"placements"] = [self gatherPlacements];
    
    NSError *error;
    NSData *Json = [NSJSONSerialization dataWithJSONObject:statsDict
                                                options:kNilOptions
                                                  error:&error];
    self.lastGatherStats = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    
    if (error) {
        PBLogError(@"Error parsing ad server response");
        return;
    }
    [self trackStats:Json];
}

- (NSMutableArray *) gatherPlacements{
    NSMutableArray *placementsArr = [[NSMutableArray alloc] init];
    
    NSMutableSet<PBAdUnit *> * adunits = [[PBBidManager sharedInstance] getRegisteredAdUnits];
    for(PBAdUnit* adunit  in adunits){
        [placementsArr addObject:[self gatherSizes:adunit]];
    }
    return placementsArr;
}


- (NSDictionary *) gatherSizes:(PBAdUnit*) adunit{
    NSMutableDictionary *sizesDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *sizesArr = [[NSMutableArray alloc] init];
    sizesDict[@"sizes"] = sizesArr;
    [sizesArr addObject:[self gatherSize: adunit]];
    
    return sizesDict;
}

- (NSDictionary *) gatherSize:(PBAdUnit*) adunit{
    NSMutableDictionary *sizeDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *adserverDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *deliveryDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *prebidDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *tiersArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *tierDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *bidsArr = [[NSMutableArray alloc] init];
    
    
    sizeDict[@"id"] = @(0);
    sizeDict[@"isDefault"] = @(adunit.isDefault);
    sizeDict[@"viaAdserver"] = @(true);
    sizeDict[@"active"] = @(true);
    sizeDict[@"timeToLoad"] = @(adunit.timeToLoad);
    
    NSString * adunitId = [adunit.adView valueForKey:@"adUnitID"];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^/" options:NSRegularExpressionCaseInsensitive error:&error];
    adunitId = [regex stringByReplacingMatchesInString:adunitId options:0 range:NSMakeRange(0, [adunitId length]) withTemplate:@""];
    
    adserverDict[@"name"] = @"DFP";
    adserverDict[@"id"] = adunitId;
    deliveryDict[@"lineitemId"] = adunit.lineItemId;
    deliveryDict[@"creativeId"] = adunit.creativeId;
    adserverDict[@"delivery"] = deliveryDict;
    sizeDict[@"adserver"] = adserverDict;
    
    sizeDict[@"prebid"] = prebidDict;
    prebidDict[@"tiers"] = tiersArr;
    [tiersArr addObject:tierDict];
    
    tierDict[@"id"] = @(0);
    tierDict[@"bids"] = bidsArr;
    
    
    for (PBBidResponse* bid in _bidsMap[adunit.identifier]){
        [bidsArr addObject:[self gatherBid:bid]];
    }
    return sizeDict;
}

- (NSDictionary *) gatherBid:(PBBidResponse*) bid {
    NSMutableDictionary *bidDict = [[NSMutableDictionary alloc] init];
    bidDict[@"bidder"] = bid.bidder;
    long cpm = round(bid.price*1000);
    bidDict[@"cpm"] = @(cpm);
    bidDict[@"size"] = [NSString stringWithFormat:@"%lux%lu",bid.width , bid.height];
    bidDict[@"time"] = @(bid.responseTime);
    bidDict[@"won"] = @(bid.won);
    bidDict[@"origCPM"] = nil;
    bidDict[@"state"] = @(bid.responseType);
    if (bid.dealId != nil) {
        bidDict[@"dealId"] = bid.dealId;
    }
    
    return bidDict;
}

@end
